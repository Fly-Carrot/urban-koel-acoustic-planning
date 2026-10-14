# Recalculate predictions and planning summaries from the retained coefficient draws.
read_retained_components <- function() {
  input <- study_input_dir(); output <- study_output_dir()
  hosts <- read_table(file.path(output,"host_coefficients.csv"))
  roles <- c(corvid="corvid_assemblage",sturnid="sturnid_assemblage",laughingthrush="black_faced_laughingthrush")
  hosts[,host_group := names(roles)[match(host_group,roles)]]
  weekly <- read_table(file.path(output,"host_weekly_scaling.csv"))
  annual <- read_table(file.path(output,"host_annual_scaling.csv"))
  for (x in list(weekly,annual)) x[,host_group := ifelse(host_group=="equal_scale","equal_scale",names(roles)[match(host_group,roles)])]
  list(hosts=hosts,weekly=weekly,annual=annual,
       beta=read_table(file.path(output,"weekly_coefficients.csv")),
       joint=read_table(file.path(output,"joint_coefficients.csv")),
       hourly=read_table(file.path(output,"hourly_coefficients.csv")),
       hourly_names=read_table(file.path(output,"hourly_columns.csv"))$term,
       training=read_table(file.path(input,"station_predictors.csv")),
       city=read_table(file.path(input,"city_predictors.csv")))
}

retained_host_models <- function(parts, m) {
  setNames(lapply(names(host_formulas()),function(role){
    rows <- parts$hosts[host_group==role & imputation==m]
    beta <- matrix(rows$coefficient,1,dimnames=list(NULL,rows$term))
    list(beta.samples=beta)
  }),names(host_formulas()))
}

standardised_city <- function(parts, city=parts$city) {
  city <- data.table::copy(city)
  for (v in environmental_predictor_names()) {
    city[[v]] <- (city[[v]]-mean(parts$training[[v]]))/stats::sd(parts$training[[v]])
  }
  city
}

retained_week_grid <- function(parts, m, city) {
  grid <- city_week_grid(city)
  models <- retained_host_models(parts,m)
  for (role in names(models)) {
    scaling <- parts$weekly[host_group==role & imputation==m]
    grid[[paste0(role,"_host_psi_z")]] <- predict_host_surface(models[[role]],1L,host_formulas()[[role]],
                                                            grid,scaling$centre,scaling$scale)
  }
  grid
}

reproduce_weekly_prediction <- function(parts, out, chunk_size=200L) {
  city <- standardised_city(parts)
  aliases <- c(corvid_assemblage_host_psi_z="corvid_host_psi_z",sturnid_assemblage_host_psi_z="sturnid_host_psi_z",
               black_faced_laughingthrush_host_psi_z="laughingthrush_host_psi_z")
  beta <- data.table::copy(parts$beta)
  for(v in names(aliases)) data.table::setnames(beta,v,aliases[[v]])
  chunks <- split(seq_len(nrow(city)),ceiling(seq_len(nrow(city))/chunk_size))
  files <- character(length(chunks))
  for (i in seq_along(chunks)) {
    predicted <- vector("list",3)
    for(m in 1:3){
      grid <- retained_week_grid(parts,m,city[chunks[[i]]])
      x <- stats::model.matrix(koel_three_host_formula(),as.data.frame(grid))
      terms <- colnames(x)
      coefficients <- as.matrix(beta[imputation==m, ..terms])
      predicted[[m]] <- stats::plogis(x %*% t(coefficients))
    }
    draws <- do.call(cbind,predicted)
    q <- matrixStats::rowQuantiles(draws,probs=c(.025,.5,.975))
    summary <- data.table::data.table(cell_id=grid$cell_id,annual_week=grid$annual_week,
                                      psi_mean=rowMeans(draws),psi_q025=q[,1],psi_median=q[,2],psi_q975=q[,3])
    files[i] <- file.path(out,sprintf("weekly_part_%03d.csv",i))
    write_table(summary,files[i])
    if(i%%10==0 || i==length(chunks)) message("Weekly prediction: ",i,"/",length(chunks)," chunks")
  }
  summary <- data.table::rbindlist(lapply(files,read_table))
  write_table(summary,file.path(out,"city_week_predictions.csv"))
  invisible(summary)
}

planning_density_grid <- function(index, gamma, hourly, names, day_quantile) {
  pad <- .02*diff(range(index)); grid <- seq(min(index)-pad,max(index)+pad,length.out=161L)
  theta <- 2*pi*((0:23)+.5)/24
  basis <- cbind(sin(theta),cos(theta),sin(2*theta),cos(2*theta))
  hour_beta <- stan_coefficients(hourly,"beta",length(names))[,match(c("sin_hour_1","cos_hour_1","sin_hour_2","cos_hour_2"),names),drop=FALSE]
  minutes <- probability <- array(NA_real_,c(161L,52L,nrow(gamma)))
  for(d in seq_len(nrow(gamma))) for(w in 1:52){
    eta_hour <- gamma[d,1]+gamma[d,3]*sin(2*pi*(w-1)/52)+gamma[d,4]*cos(2*pi*(w-1)/52)+
      drop(basis%*%hour_beta[d,])+hourly[d,"sigma_day"]*day_quantile[d]
    eta <- outer(grid*gamma[d,2],eta_hour,"+")
    metric <- conditional_window_metrics(eta,exp(hourly[d,"log_phi"]))
    minutes[,w,d]<-metric$expected;probability[,w,d]<-metric$probability
  }
  list(grid=grid,minutes=minutes,probability=probability)
}

interpolate_retained_metric <- function(grid, values, index) {
  lower<-pmin(findInterval(index,grid,all.inside=TRUE),length(grid)-1L)
  weight<-(index-grid[lower])/(grid[lower+1L]-grid[lower])
  low<-matrix(values[lower,,drop=FALSE],length(index),52L)
  high<-matrix(values[lower+1L,,drop=FALSE],length(index),52L)
  low+weight*(high-low)
}

reproduce_planning <- function(parts, out) {
  weights <- read_table(file.path(study_input_dir(),"planning_weights.csv"))
  ids <- unique(weights$cell_id)
  city <- standardised_city(parts,parts$city[match(ids,cell_id)])
  reference <- read_table(file.path(study_output_dir(),"group_posterior_draw_metrics.csv"))
  all <- list()
  hourly <- as.matrix(parts$hourly[,setdiff(names(parts$hourly),c("draw","source_row")),with=FALSE])
  for(m in 1:3){
    grid <- retained_week_grid(parts,m,city)
    x <- stats::model.matrix(koel_three_host_formula(),as.data.frame(grid))
    joint <- as.matrix(parts$joint[imputation==m,setdiff(names(parts$joint),c("imputation","draw","source_row")),with=FALSE])
    beta <- stan_coefficients(joint,"beta_occ",ncol(x));alpha<-stan_coefficients(joint,"alpha_det",4L);gamma<-stan_coefficients(joint,"gamma_int",4L)
    reference_data <- read_json_gz(file.path(study_input_dir(),"daily",sprintf("full_HEQZ_M%02d.json.gz",m)))
    p <- stats::plogis(drop(alpha%*%reference_data$x_det_reference))
    models<-retained_host_models(parts,m)
    index<-annual_equal_scale_host(models,data.frame(host_group=names(models),draw_index=1L),as.data.frame(grid),as.data.frame(parts$annual),m)
    index<-index[seq(1L,length(index),by=52L)]
    set.seed(475027L+100L+m);day<-sample(stats::qnorm((seq_len(nrow(joint))-.5)/nrow(joint)),replace=FALSE)
    density<-planning_density_grid(index,gamma,hourly,parts$hourly_names,day)
    for(d in seq_len(nrow(joint))){
      psi<-matrix(stats::plogis(x%*%beta[d,]),nrow(city),52L,byrow=TRUE)
      minute<-psi*p[d]*interpolate_retained_metric(density$grid,density$minutes[,,d],index)
      prob<-psi*p[d]*interpolate_retained_metric(density$grid,density$probability[,,d],index)
      for(key in unique(paste(weights$layer,weights$context_class,sep="|"))){
        w<-weights[paste(layer,context_class,sep="|")==key]
        i<-match(w$cell_id,city$cell_id);denom<-sum(w$weight)
        curve<-drop(crossprod(w$weight,psi[i,,drop=FALSE]))/denom
        all[[length(all)+1L]]<-data.table::data.table(group_type=w$layer[1],group_name=w$context_class[1],imputation=m,within_imputation_draw=d,
          annual_mean_psi=mean(curve),w10_w30_mean_psi=mean(curve[10:30]),peak_week=which.max(curve),
          dawn_w15_w21_expected_positive_sampled_minutes=mean(drop(crossprod(w$weight,minute[i,15:21,drop=FALSE]))/denom),
          dawn_w15_w21_probability_at_least_one=mean(drop(crossprod(w$weight,prob[i,15:21,drop=FALSE]))/denom))
      }
    }
    message("Planning posterior: imputation ",m,"/3")
  }
  result<-data.table::rbindlist(all)
  write_table(result,file.path(out,"planning_draw_metrics.csv"))
  metric_names <- c("annual_mean_psi","w10_w30_mean_psi",
    "dawn_w15_w21_expected_positive_sampled_minutes","dawn_w15_w21_probability_at_least_one")
  summary <- data.table::rbindlist(lapply(metric_names,function(v)
    result[, .(metric=v,mean=mean(get(v)),median=stats::median(get(v)),
               q025=stats::quantile(get(v),.025,names=FALSE),
               q975=stats::quantile(get(v),.975,names=FALSE)),by=.(group_type,group_name)]))
  write_table(summary,file.path(out,"planning_overlap_summary.csv"))
  keys<-c("group_type","group_name","imputation","within_imputation_draw")
  paired<-merge(result,reference,by=keys,suffixes=c("_new","_reference"))
  metrics<-c("annual_mean_psi","w10_w30_mean_psi","dawn_w15_w21_expected_positive_sampled_minutes","dawn_w15_w21_probability_at_least_one")
  check<-data.table::data.table(metric=metrics,max_absolute_difference=vapply(metrics,function(v)max(abs(paired[[paste0(v,"_new")]]-paired[[paste0(v,"_reference")]])),numeric(1)))
  write_table(check,file.path(out,"planning_parity.csv"))
  stopifnot(nrow(paired)==2700L,all(check$max_absolute_difference<1e-8))
  invisible(result)
}

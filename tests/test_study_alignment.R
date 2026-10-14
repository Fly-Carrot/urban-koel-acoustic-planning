# Tests against released study inputs, not just simulated examples.
source('R/full_pipeline.R');source('R/study_inputs.R')
calendar<-read_table(file.path(study_input_dir(),'calendar.csv'))
weeks<-read_table(file.path(study_input_dir(),'fitting_weeks.csv'))
season<-dated_terms(weeks$week_start)
stopifnot(nrow(weeks)==68L,max(abs(season$sin_week-weeks$sin_week))<1e-13,
          max(abs(season$cos_week-weeks$cos_week))<1e-13,
          as.numeric(max(diff(as.Date(weeks$week_start))))==42,
          identical(as.integer(reporting_week(c('2025-01-01','2025-12-31'))),c(1L,52L)))
input<-read_occupancy_input('full_H4_M01')$data
design<-tpg_design(input,primary_detection_formula(),'det')
stopifnot(nrow(design)==31L*68L*7L)
parts<-list(training=read_table(file.path(study_input_dir(),'station_predictors.csv')),
            city=read_table(file.path(study_input_dir(),'city_predictors.csv')))
actual<-classify_prediction_support(parts$training,parts$city)
ref<-read_table(file.path(study_output_dir(),'support_reference.csv'))
stopifnot(identical(actual$support_class,ref$support_class),
          max(abs(actual$aoa_distance-ref$aoa_distance))<1e-10,
          all(actual$support_class[actual$pid=='PASS' & actual$aoa_class=='Boundary']=='Primary Results'))
# A non-finite predictor must never be presented as uncertain-but-usable.
bad<-data.table::copy(parts$city[1]);bad$trees<-NA_real_
stopifnot(classify_prediction_support(parts$training,bad)$support_class=='Invalid Data')
eta<-matrix(qlogis(.1),1,24);metric<-conditional_window_metrics(eta,50)
p0<-exp(lbeta(.1*50,6+.9*50)-lbeta(.1*50,.9*50))
stopifnot(abs(metric$expected-24*.1/(1-p0^24))<1e-12,
          abs(metric$probability-(1-p0^4)/(1-p0^24))<1e-12)
cat('Study calendar, row-preserving designs, full AOA classes and dawn conditioning passed.\n')

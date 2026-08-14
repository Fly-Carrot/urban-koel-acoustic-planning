functions {
  real positive_day_hourly_lpmf(
      array[] int k,
      array[] int n,
      matrix X,
      int start_hour,
      int end_hour,
      vector gamma_hour,
      real day_effect,
      real phi) {
    real log_probability = 0;
    real log_all_zero = 0;
    for (r in start_hour:end_hour) {
      real mu = fmin(
        1 - 1e-9,
        fmax(1e-9, inv_logit(X[r] * gamma_hour + day_effect))
      );
      real alpha_bb = mu * phi;
      real beta_bb = (1 - mu) * phi;
      log_probability += beta_binomial_lpmf(
        k[r] | n[r], alpha_bb, beta_bb
      );
      log_all_zero += beta_binomial_lpmf(
        0 | n[r], alpha_bb, beta_bb
      );
    }
    return log_probability - log1m_exp(log_all_zero);
  }
}

data {
  int<lower=1> G;
  int<lower=1> D;
  int<lower=1> S;
  int<lower=1> P_occ;
  int<lower=1> P_det;
  int<lower=1> P_hour;
  matrix[G, P_occ] X_occ;
  matrix[D, P_det] X_det;
  array[D] int<lower=1, upper=S> site_id;
  array[D] int<lower=0, upper=1> detected;
  array[G] int<lower=1, upper=D> start_day;
  array[G] int<lower=1, upper=D> end_day;
  array[G] int<lower=0, upper=1> any_positive;

  int<lower=1> J;
  int<lower=1> R;
  matrix[R, P_hour] X_hour;
  array[R] int<lower=0> k_hour;
  array[R] int<lower=1> n_hour;
  array[J] int<lower=1, upper=R> start_hour;
  array[J] int<lower=1, upper=R> end_hour;
  array[D] int<lower=0, upper=J> positive_day_id;
}

parameters {
  vector[P_occ] beta_occ;
  vector[P_det] alpha_det;
  vector[P_hour] gamma_hour;
  vector[S] site_det_raw;
  real<lower=0> sigma_det;
  vector[J] day_raw;
  real<lower=0> sigma_day;
  real<lower=log(0.01), upper=log(1e5)> log_phi;
}

transformed parameters {
  vector[S] site_det = sigma_det * (
    site_det_raw - rep_vector(mean(site_det_raw), S)
  );
  vector[J] day_effect = sigma_day * (
    day_raw - rep_vector(mean(day_raw), J)
  );
  real<lower=0> phi = exp(log_phi);
}

model {
  beta_occ ~ normal(0, 2.25);
  alpha_det ~ normal(0, 2.25);
  gamma_hour[1] ~ normal(-4, 3);
  if (P_hour > 1) {
    gamma_hour[2:P_hour] ~ normal(0, 1.25);
  }
  site_det_raw ~ std_normal();
  sigma_det ~ normal(0, 1);
  day_raw ~ std_normal();
  sigma_day ~ normal(0, 1);
  log_phi ~ normal(log(50), 1.5);

  for (g in 1:G) {
    real eta_occ = X_occ[g] * beta_occ;
    real log_lik_if_present = 0;
    for (d in start_day[g]:end_day[g]) {
      real eta_det = X_det[d] * alpha_det + site_det[site_id[d]];
      if (detected[d] == 1) {
        int j = positive_day_id[d];
        log_lik_if_present += bernoulli_logit_lpmf(1 | eta_det);
        log_lik_if_present += positive_day_hourly_lpmf(
          k_hour | n_hour, X_hour,
          start_hour[j], end_hour[j],
          gamma_hour, day_effect[j], phi
        );
      } else {
        log_lik_if_present += bernoulli_logit_lpmf(0 | eta_det);
      }
    }
    if (any_positive[g] == 1) {
      target += bernoulli_logit_lpmf(1 | eta_occ)
                + log_lik_if_present;
    } else {
      target += log_sum_exp(
        bernoulli_logit_lpmf(0 | eta_occ),
        bernoulli_logit_lpmf(1 | eta_occ) + log_lik_if_present
      );
    }
  }
}

generated quantities {
  vector[G] log_lik_group;

  for (g in 1:G) {
    real eta_occ = X_occ[g] * beta_occ;
    real log_lik_if_present = 0;
    for (d in start_day[g]:end_day[g]) {
      real eta_det = X_det[d] * alpha_det + site_det[site_id[d]];
      if (detected[d] == 1) {
        int j = positive_day_id[d];
        log_lik_if_present += bernoulli_logit_lpmf(1 | eta_det);
        log_lik_if_present += positive_day_hourly_lpmf(
          k_hour | n_hour, X_hour,
          start_hour[j], end_hour[j],
          gamma_hour, day_effect[j], phi
        );
      } else {
        log_lik_if_present += bernoulli_logit_lpmf(0 | eta_det);
      }
    }
    if (any_positive[g] == 1) {
      log_lik_group[g] =
        bernoulli_logit_lpmf(1 | eta_occ) + log_lik_if_present;
    } else {
      log_lik_group[g] = log_sum_exp(
        bernoulli_logit_lpmf(0 | eta_occ),
        bernoulli_logit_lpmf(1 | eta_occ) + log_lik_if_present
      );
    }
  }
}

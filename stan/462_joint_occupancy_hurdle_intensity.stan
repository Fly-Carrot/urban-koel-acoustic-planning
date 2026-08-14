functions {
  real zero_truncated_beta_binomial_lpmf(
      int k, int n, real mu, real phi) {
    real alpha_bb = mu * phi;
    real beta_bb = (1 - mu) * phi;
    real log_p0 = beta_binomial_lpmf(0 | n, alpha_bb, beta_bb);
    return beta_binomial_lpmf(k | n, alpha_bb, beta_bb)
           - log1m_exp(log_p0);
  }
}

data {
  int<lower=1> G;
  int<lower=1> D;
  int<lower=1> S;
  int<lower=1> P_occ;
  int<lower=1> P_det;
  int<lower=1> P_int;
  matrix[G, P_occ] X_occ;
  matrix[D, P_det] X_det;
  matrix[D, P_int] X_int;
  array[D] int<lower=1, upper=S> site_id;
  array[D] int<lower=0, upper=1> detected;
  array[D] int<lower=0> k;
  array[D] int<lower=1> n;
  array[G] int<lower=1, upper=D> start_day;
  array[G] int<lower=1, upper=D> end_day;
  array[G] int<lower=0, upper=1> any_positive;
  vector[P_det] x_det_reference;
  int<lower=1> n_reference;
}

parameters {
  vector[P_occ] beta_occ;
  vector[P_det] alpha_det;
  vector[P_int] gamma_int;
  vector[S] site_det_raw;
  real<lower=0> sigma_det;
  real<lower=log(0.01), upper=log(1e5)> log_phi;
}

transformed parameters {
  vector[S] site_det = sigma_det * (
    site_det_raw - rep_vector(mean(site_det_raw), S)
  );
  real<lower=0> phi = exp(log_phi);
}

model {
  beta_occ ~ normal(0, 2.25);
  alpha_det ~ normal(0, 2.25);
  gamma_int[1] ~ normal(-4, 3);
  if (P_int > 1) {
    gamma_int[2:P_int] ~ normal(0, 2);
  }
  site_det_raw ~ std_normal();
  sigma_det ~ normal(0, 1);
  log_phi ~ normal(log(50), 1.5);

  for (g in 1:G) {
    real eta_occ = X_occ[g] * beta_occ;
    real log_lik_if_present = 0;
    for (r in start_day[g]:end_day[g]) {
      real eta_det = X_det[r] * alpha_det + site_det[site_id[r]];
      if (detected[r] == 1) {
        real mu_int = fmin(
          1 - 1e-9,
          fmax(1e-9, inv_logit(X_int[r] * gamma_int))
        );
        log_lik_if_present += bernoulli_logit_lpmf(1 | eta_det);
        log_lik_if_present += zero_truncated_beta_binomial_lpmf(
          k[r] | n[r], mu_int, phi
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
  vector[G] psi_group;
  vector[G] mu_int_group;
  vector[G] detected_day_density_reference;
  vector[G] occurrence_conditional_observed_activity;
  vector[G] integrated_recorded_acoustic_opportunity;
  vector[G] expected_positive_days;
  vector[G] positive_week_probability;
  vector[G] expected_positive_minutes;
  real p_detection_reference;

  p_detection_reference = inv_logit(
    dot_product(x_det_reference, alpha_det)
  );

  for (g in 1:G) {
    real eta_occ = X_occ[g] * beta_occ;
    real log_lik_if_present = 0;
    real log_no_detection_if_present = 0;
    real expected_days_if_present = 0;
    real expected_minutes_if_present = 0;
    real mu_ref = fmin(
      1 - 1e-9,
      fmax(1e-9, inv_logit(X_int[start_day[g]] * gamma_int))
    );
    real alpha_ref = mu_ref * phi;
    real beta_ref = (1 - mu_ref) * phi;
    real p0_ref = exp(
      beta_binomial_lpmf(0 | n_reference, alpha_ref, beta_ref)
    );
    real positive_density_ref = mu_ref / fmax(1 - p0_ref, 1e-12);

    psi_group[g] = inv_logit(eta_occ);
    mu_int_group[g] = mu_ref;
    detected_day_density_reference[g] = positive_density_ref;
    occurrence_conditional_observed_activity[g] =
      p_detection_reference * positive_density_ref;
    integrated_recorded_acoustic_opportunity[g] =
      psi_group[g] * occurrence_conditional_observed_activity[g];

    for (r in start_day[g]:end_day[g]) {
      real eta_det = X_det[r] * alpha_det + site_det[site_id[r]];
      real p_det = inv_logit(eta_det);
      real mu_int = fmin(
        1 - 1e-9,
        fmax(1e-9, inv_logit(X_int[r] * gamma_int))
      );
      real alpha_bb = mu_int * phi;
      real beta_bb = (1 - mu_int) * phi;
      real p0 = exp(beta_binomial_lpmf(0 | n[r], alpha_bb, beta_bb));
      real positive_density = mu_int / fmax(1 - p0, 1e-12);

      log_no_detection_if_present += log1m(p_det);
      expected_days_if_present += p_det;
      expected_minutes_if_present += p_det * n[r] * positive_density;

      if (detected[r] == 1) {
        log_lik_if_present += bernoulli_logit_lpmf(1 | eta_det);
        log_lik_if_present += zero_truncated_beta_binomial_lpmf(
          k[r] | n[r], mu_int, phi
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
    expected_positive_days[g] =
      psi_group[g] * expected_days_if_present;
    positive_week_probability[g] =
      psi_group[g] * (1 - exp(log_no_detection_if_present));
    expected_positive_minutes[g] =
      psi_group[g] * expected_minutes_if_present;
  }
}

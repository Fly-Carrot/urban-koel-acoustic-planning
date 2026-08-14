functions {
  real beta_binomial_zero_lpmf(int n, real mu, real phi) {
    real alpha_bb = mu * phi;
    real beta_bb = (1 - mu) * phi;
    return beta_binomial_lpmf(0 | n, alpha_bb, beta_bb);
  }
}

data {
  int<lower=1> J;
  int<lower=1> R;
  int<lower=1> P;
  matrix[R, P] X;
  array[R] int<lower=1, upper=J> day_id;
  array[R] int<lower=0> k;
  array[R] int<lower=1> n;
  array[J] int<lower=1, upper=R> start_hour;
  array[J] int<lower=1, upper=R> end_hour;
}

parameters {
  vector[P] beta;
  vector[J] day_raw;
  real<lower=0> sigma_day;
  real<lower=log(0.1), upper=log(1e5)> log_phi;
}

transformed parameters {
  vector[J] day_effect = sigma_day * (
    day_raw - rep_vector(mean(day_raw), J)
  );
  real<lower=0> phi = exp(log_phi);
}

model {
  beta[1] ~ normal(-4, 2.5);
  if (P > 1) {
    beta[2:P] ~ normal(0, 1.25);
  }
  day_raw ~ std_normal();
  sigma_day ~ normal(0, 1);
  log_phi ~ normal(log(50), 1.5);

  for (j in 1:J) {
    real day_log_lik = 0;
    real log_p_all_zero = 0;
    for (r in start_hour[j]:end_hour[j]) {
      real mu = fmin(
        1 - 1e-9,
        fmax(1e-9, inv_logit(X[r] * beta + day_effect[j]))
      );
      real alpha_bb = mu * phi;
      real beta_bb = (1 - mu) * phi;
      day_log_lik += beta_binomial_lpmf(
        k[r] | n[r], alpha_bb, beta_bb
      );
      log_p_all_zero += beta_binomial_zero_lpmf(
        n[r] | mu, phi
      );
    }
    target += day_log_lik - log1m_exp(log_p_all_zero);
  }
}

generated quantities {
  vector[J] log_lik_day;
  vector[J] expected_positive_minutes;
  vector[J] expected_positive_fraction;

  for (j in 1:J) {
    real day_log_lik = 0;
    real log_p_all_zero = 0;
    real expected_minutes_unconditional = 0;
    real total_minutes = 0;

    for (r in start_hour[j]:end_hour[j]) {
      real mu = fmin(
        1 - 1e-9,
        fmax(1e-9, inv_logit(X[r] * beta + day_effect[j]))
      );
      real alpha_bb = mu * phi;
      real beta_bb = (1 - mu) * phi;
      day_log_lik += beta_binomial_lpmf(
        k[r] | n[r], alpha_bb, beta_bb
      );
      log_p_all_zero += beta_binomial_zero_lpmf(
        n[r] | mu, phi
      );
      expected_minutes_unconditional += n[r] * mu;
      total_minutes += n[r];
    }

    log_lik_day[j] =
      day_log_lik - log1m_exp(log_p_all_zero);
    expected_positive_minutes[j] =
      expected_minutes_unconditional /
      fmax(1 - exp(log_p_all_zero), 1e-12);
    expected_positive_fraction[j] =
      expected_positive_minutes[j] / total_minutes;
  }
}

# Stan models

These four programs define the daily and hourly calling-density models. Compiled binaries and raw chains are not included.

| File | Role |
|---|---|
| [462_joint_occupancy_hurdle_intensity.stan](462_joint_occupancy_hurdle_intensity.stan) | Weekly opportunity, daily detection and positive-day minute counts |
| [463_joint_intensity_host_season_compare.stan](463_joint_intensity_host_season_compare.stan) | Host-informed and season-only daily density comparison |
| [470_conditional_hourly_density.stan](470_conditional_hourly_density.stan) | Cyclic hourly density, conditional on a positive day |
| [471_integrated_hourly_joint.stan](471_integrated_hourly_joint.stan) | Integrated check linking hourly density to the weekly and daily layers |

`make full` calls models 462 and 470 through [R/calling_density.R](../R/calling_density.R). Models 463 and 471 are provided for the comparison and integrated check. `make verify` checks stored summaries and does not compile Stan. See [model roles](../docs/model_registry.md).

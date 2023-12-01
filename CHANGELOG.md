# Changelog

## [0.3.0](https://github.com/rancher/terraform-null-rke2-install/compare/v0.2.7...v0.3.0) (2023-12-01)


### Features

* rely on identifier for rke2 lifecycle rather than detecting fil… ([#87](https://github.com/rancher/terraform-null-rke2-install/issues/87)) ([2b83ba1](https://github.com/rancher/terraform-null-rke2-install/commit/2b83ba11745339629228d44ec00631f23af584aa))


### Bug Fixes

* make sure names are unique ([#89](https://github.com/rancher/terraform-null-rke2-install/issues/89)) ([eebfe81](https://github.com/rancher/terraform-null-rke2-install/commit/eebfe81e183080d66684e4f1b806e481994577f6))

## [0.2.7](https://github.com/rancher/terraform-null-rke2-install/compare/v0.2.6...v0.2.7) (2023-11-28)


### Bug Fixes

* add generated files to track files generated in other modules ([#82](https://github.com/rancher/terraform-null-rke2-install/issues/82)) ([fa3bca9](https://github.com/rancher/terraform-null-rke2-install/commit/fa3bca923e403a5dae894662d7286448446b23f7))
* add owner to workflow and skip github .42 ([#85](https://github.com/rancher/terraform-null-rke2-install/issues/85)) ([6b6d2cc](https://github.com/rancher/terraform-null-rke2-install/commit/6b6d2cc9f8e2beb7cd892f15df7dd1afea94a122))
* remove the md5 file hash ([#86](https://github.com/rancher/terraform-null-rke2-install/issues/86)) ([9702810](https://github.com/rancher/terraform-null-rke2-install/commit/9702810df38e6964aa572bd4d43c6e90c4381986))
* upgrade examples and add github token to workflow ([#84](https://github.com/rancher/terraform-null-rke2-install/issues/84)) ([87a4c03](https://github.com/rancher/terraform-null-rke2-install/commit/87a4c03729093d452e38a7f596a0cda18c34e174))

## [0.2.6](https://github.com/rancher/terraform-null-rke2-install/compare/v0.2.5...v0.2.6) (2023-10-30)


### Bug Fixes

* fix workflow conditional ([#80](https://github.com/rancher/terraform-null-rke2-install/issues/80)) ([7eb3b1f](https://github.com/rancher/terraform-null-rke2-install/commit/7eb3b1f3db8919a41f76bd404c192bd870aab953))

## [0.2.5](https://github.com/rancher/terraform-null-rke2-install/compare/v0.2.4...v0.2.5) (2023-10-30)


### Bug Fixes

* remove json conversion ([#78](https://github.com/rancher/terraform-null-rke2-install/issues/78)) ([ee597f3](https://github.com/rancher/terraform-null-rke2-install/commit/ee597f3ef42fdfdab2212e5df250bb1f7d036cb4))

## [0.2.4](https://github.com/rancher/terraform-null-rke2-install/compare/v0.2.3...v0.2.4) (2023-10-30)


### Bug Fixes

* skip e2e tests if no pr generated ([#76](https://github.com/rancher/terraform-null-rke2-install/issues/76)) ([8a4d533](https://github.com/rancher/terraform-null-rke2-install/commit/8a4d533310bee3a3a1ad671b6577c89fb0e60646))

## [0.2.3](https://github.com/rancher/terraform-null-rke2-install/compare/v0.2.2...v0.2.3) (2023-10-30)


### Bug Fixes

* systemctl can form an endless loop, use poll with timeout instead ([#74](https://github.com/rancher/terraform-null-rke2-install/issues/74)) ([76fa666](https://github.com/rancher/terraform-null-rke2-install/commit/76fa666fed3a57131c374794e4eed6f8fd6a7ad7))

## [0.2.2](https://github.com/rancher/terraform-null-rke2-install/compare/v0.2.1...v0.2.2) (2023-10-27)


### Bug Fixes

* Expose errors when starting service ([#72](https://github.com/rancher/terraform-null-rke2-install/issues/72)) ([eb1fdf4](https://github.com/rancher/terraform-null-rke2-install/commit/eb1fdf47374b9ac42e700e0a2bca213bfe768e19))

## [0.2.1](https://github.com/rancher/terraform-null-rke2-install/compare/v0.2.0...v0.2.1) (2023-10-26)


### Bug Fixes

* expose the error if the service start fails ([#70](https://github.com/rancher/terraform-null-rke2-install/issues/70)) ([3c993b8](https://github.com/rancher/terraform-null-rke2-install/commit/3c993b87f760cf492c55b4027490747165be1f0c))

## [0.2.0](https://github.com/rancher/terraform-null-rke2-install/compare/v0.1.1...v0.2.0) (2023-10-25)


### Features

* remove variable for rke2 config and rely on local_file_path ([#68](https://github.com/rancher/terraform-null-rke2-install/issues/68)) ([c0ee6b6](https://github.com/rancher/terraform-null-rke2-install/commit/c0ee6b6bff38668e4e57ffb6480fbbcdcf40b369))

## [0.1.1](https://github.com/rancher/terraform-null-rke2-install/compare/v0.1.0...v0.1.1) (2023-10-19)


### Bug Fixes

* add a pinned terraform version to flake and fix remind workflow ([#55](https://github.com/rancher/terraform-null-rke2-install/issues/55)) ([aab5a5e](https://github.com/rancher/terraform-null-rke2-install/commit/aab5a5ed5c5f0467e2ef0fe666e8ed6e134cfe4f))
* add url to test in reminder ([#67](https://github.com/rancher/terraform-null-rke2-install/issues/67)) ([0651796](https://github.com/rancher/terraform-null-rke2-install/commit/0651796dc12fc0509e0cea3c1f836246414884f5))
* checkout main for e2e tests ([#64](https://github.com/rancher/terraform-null-rke2-install/issues/64)) ([0a3eb54](https://github.com/rancher/terraform-null-rke2-install/commit/0a3eb5405967795a4e1af578c911dfc514e6afae))
* fix spacing ([#66](https://github.com/rancher/terraform-null-rke2-install/issues/66)) ([0c60588](https://github.com/rancher/terraform-null-rke2-install/commit/0c60588e174caf76298ea37951d6ab9d52c47ddf))
* fix workflow permissions ([#59](https://github.com/rancher/terraform-null-rke2-install/issues/59)) ([f08ffca](https://github.com/rancher/terraform-null-rke2-install/commit/f08ffca243b22d68150ff28255e95bade7a25f00))
* get release-please pr number from json string ([#62](https://github.com/rancher/terraform-null-rke2-install/issues/62)) ([7d64b3e](https://github.com/rancher/terraform-null-rke2-install/commit/7d64b3e3134fd9edc83b668cecc8fd7858566f98))
* Move e2e test trigger to release PR ([#60](https://github.com/rancher/terraform-null-rke2-install/issues/60)) ([f0355c4](https://github.com/rancher/terraform-null-rke2-install/commit/f0355c4103063b6ed0792b516d498c2ba95eb8e0))
* remove debug line ([#63](https://github.com/rancher/terraform-null-rke2-install/issues/63)) ([b0f9daa](https://github.com/rancher/terraform-null-rke2-install/commit/b0f9daacd4987f345e216bf2e3fbb84b3bd6f6d5))
* remove env for release ([#61](https://github.com/rancher/terraform-null-rke2-install/issues/61)) ([8e32766](https://github.com/rancher/terraform-null-rke2-install/commit/8e32766245a53d737a6e1440149882fdf8b58be4))
* set tf version in release tests ([#65](https://github.com/rancher/terraform-null-rke2-install/issues/65)) ([c5910e8](https://github.com/rancher/terraform-null-rke2-install/commit/c5910e8a2e76b9ed23a4846db121e30dc83f3021))
* update readme to explain test suite ([#58](https://github.com/rancher/terraform-null-rke2-install/issues/58)) ([116815f](https://github.com/rancher/terraform-null-rke2-install/commit/116815f1483f78928f8dfc9164b074fb93cbe81c))
* upgrade terraform version in ci ([#57](https://github.com/rancher/terraform-null-rke2-install/issues/57)) ([f0be02b](https://github.com/rancher/terraform-null-rke2-install/commit/f0be02b50ec647f7142d15b60b6a997b99076441))

## [0.1.0](https://github.com/rancher/terraform-null-rke2-install/compare/v0.0.21...v0.1.0) (2023-10-17)


### Features

* add workflows to start automatically releasing ([#52](https://github.com/rancher/terraform-null-rke2-install/issues/52)) ([5134453](https://github.com/rancher/terraform-null-rke2-install/commit/5134453c49cb6ba7e4488c4bed157e82a3b059f5))

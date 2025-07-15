# What's new in Chart Version 8.0.18

* Support for DevOps Deploy 8.1.2.0
* DevOps Deploy server image now installs OpenJDK 11 instead of IBM JRE 8.  Keystore file migration is handled automatically.

## Breaking Changes
* Rollback to previous versions of DevOps Deploy server is not supported without manual intervention because database schema changes are present.  Manual steps can be found [here](https://community.ibm.com/community/user/wasdevops/blogs/laurel-dickson-bull1/2022/07/08/container-upgrade).
* Helm 3 is now used for deploying the DevOps Deploy Server.  Direct upgrade for DevOps Deploy server deployed via Helm 2 is not supported. Please use the Helm 2to3 Plugin to perform migration (https://github.com/helm/helm-2to3/blob/master/README.md)

# Fixes

# Prerequisites
* See README for prerequisites

# Version History

This version of the Helm chart supports product versions 7.2.1.1 - 8.1.2.0, as well as security releases from 7.1.2.9 and forward.

| Chart | Date | Image(s) Supported | Breaking Changes | Details |
| ----- | ---- | ------------------ | ---------------- | ------- |
| 8.0.18 |June 17th, 2025 | ucds: sha256:34aad9c6e56eaf0a5ac7e9a47bed7f7c83ad127b8026406fae0179bf09b6e2bc | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.1.2.0 |
| 8.0.17 | March 25th, 2025 | ucds: sha256:dd2c5831d970b113a030d53497037c10310c646c3a21ff7c3c911e18b45fbab3 | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.1.1.0 |
| 8.0.16 | January 28th, 2025 | ucds: sha256:b51f7d1c5fc1fc1afa1ab8d45f9c7ffe6f74deeb4c8278f5ea94416c218e6dce | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.1.0.1 |
| 8.0.15 | November 26th, 2024 | ucds: sha256:19d786fab318319312070008638d37ae9ceca2c1001068f244b0729fa1721a67 | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.1.0.0 |
| 8.0.14 | June 25th, 2024 | ucds: sha256:3e965d9b41d3ef1b492853e15c95f2a02094f71f31493514f29f50448746fcf3 | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.0.1.2 |
| 8.0.13 | May 14th, 2024 | ucds: sha256:8819d318b5bdacc2dafdf3e4e9020496c2040dced0b20199ac8b0dcf0518f43a | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.0.1.1 |
| 8.0.12 | April 2nd, 2024 | ucds: sha256:c1eca3567501049ae1145788874727de146431e72b9f9f4ec039ead804584fa2 | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.0.1.0 |
| 8.0.11 | January 30th, 2024 | ucds: sha256:1cafd54dc874343751a68f53f3d78b8cc4d38a93e4d4815b81795ebd1c785e27 | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.0.0.1 |
| 8.0.10 | December 19th, 2023 | ucds: sha256:428562d18cc417149887e8aa4bb3cd16501c05998ffbdb2696f8089d32191660 | Rollback to previous versions of DevOps Deploy server not supported | Support for DevOps Deploy Server 8.0.0.0 |
| 8.0.9 | September 26th, 2023 | ucds: sha256:2b5c07073b3fb812867928f6ac8d9f09c9fb65ac59808d20ef0618ab969c12d3 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.3.2.2 |
| 8.0.8 | August 15th, 2023 | ucds: sha256:4ef119fcb2f7610c3fa86880204c60e64012197cae5b60800fd447f109e60a4c | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.3.2.1 |
| 8.0.7 | July 13th, 2023 | ucds: sha256:e066d8582d8db5bc379d37113d2b19bfe5bbaefc5853bbfe3cb52fade02efcc2 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.3.2.0 |
| 8.0.6 | May 2nd, 2023 | ucds: sha256:e7d25b2f76a72018c62f7c8c87b7e96a965cf07e0db317d69030bee187ac8ef7 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.3.1.1 |
| 8.0.5 | April 4th, 2023 | ucds: sha256:8115a493365bb979c7d3231c102611cd2e2530d4f61d7961e239f416cd2e0912 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.3.1.0 |
| 8.0.4 | December 13th, 2022 | ucds: sha256:79cf716ec428889436cab9eeda3bb8c5a0b01d6c1911f0c976e915178e3d8fce | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.3.0.1 |
| 8.0.3 | November 22nd, 2022 | ucds: sha256:545c86b0986a0d07d95acd1193626350e1a1eaa068517de24c7cf8d96cd08770 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.3.0.0 |
| 8.0.2 | August 30th, 2022 | ucds: sha256:c3251d5d41118f3f8162b1ce9c5e2a47e1f590337a4f3f08c4aa874c98ec3e38 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.3.1.ifix01 |
| 8.0.1 | July 26th, 2022 | ucds: sha256:7be7875e42cbda92479233ac6895b1a4f701b09987da8744cee0260b95685df7 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.3.1 |
| 8.0.0 | June 28th, 2022 | ucds: sha256:545c0f9a5f0d4c503e45d089f342c66f54d2abe6adcecabb7a0b3c764ca44603 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.3.0 |
| 7.3.7 | April 19th, 2022 | ucds: sha256:3fccd6bef1154519cea255964cae68b3a2e4151796dc542ad8f1c7d59b068e1c | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.2.1 |
| 7.3.6 | March 22nd, 2022 | ucds: sha256:df8916fb179e4d5ef073c6c63558053149ff19d175727cf6805226022cf96483 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.2.0 |
| 7.3.5 | January 18th, 2022 | ucds: sha256:50576f600fbd95903cea6dae8916ceb0a70412397cd291ef950740e60201b843 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.1.2 |
| 7.3.4 | December 14th, 2021 | ucds: sha256:6dc51e00ef35ec5afaf4a17bf8bb5a69b906d286e6e05becf0a0efa3b5a7ea5f | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.1.1 |
| 7.3.3 | November 2nd, 2021 | ucds: sha256:37773fc4dac2ef6a4081db1174fec4b0747ef0999f1175c5aac0cb971dec4871 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.1.0 |
| 7.3.2 | September 7th, 2021 | ucds: sha256:e26d1f804d7b3d2589e237ec5a99416fa90bca7f329035c44ddd1a708912aff0 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.0.2 |
| 7.3.1 | August 3rd, 2021 | ucds: sha256:c6c420f395d46ed2da00a8d567d47a660b8be38145c47da8220edf2a6cec9d40 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.0.1 |
| 7.3.0 | July 6th, 2021 | ucds: sha256:da3189d626de2d8b9950d509deb715678540d49fad4a340bfc4050db70988de8 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.2.0.0 |
| 7.2.1 | April 20th, 2021 | ucds: sha256:2b8f7e818f856839bd5ff1c1f859381fdbce3d4725007d50a50e54e7b74dcdd4 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.2.1 |
| 7.2.0 | March 30th, 2021 | ucds: sha256:663c0edac088b86b69abecd3323d1ecee8e3a81904aec08a67054fd1bc941fbf | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.2.0 |
| 7.1.2 | January 12th, 2021 | ucds: sha256:2644047f3c683abf265846f4e98bc69952b4c672b16a916371c4d86106007039 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.1.2 |
| 7.1.1 | November 24th, 2020 | ucds: sha256:73130abeae856d2c3d08320d21ef3b677809419136c5880625206579ddb4af2c | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.1.1 |
| 7.1.0 | November 3rd, 2020 | ucds: sha256:4f1fdc20a2cb4eb789188428d89652681a6299beb0b665ff910182dc82c5ee60 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.1.0 |
| 7.0.4 | September 15th, 2020 | ucds: 7.1.0.3.1069281 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.0.3 |
| 7.0.3 | August 18th, 2020 | ucds: 7.1.0.2.1063225 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.0.2 |
| 7.0.2 | July 21st, 2020 | ucds: 7.1.0.1.ifix01.1062130 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.0.1.ifix01 |
| 7.0.1 | June 23rd, 2020 | ucds: 7.1.0.0.1058690 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.1.0.0 |
| 6.0.8 | March 24th, 2020 | ucds: 7.0.5.2.1050384 | Rollback of previous versions of UCD server not supported | Support for UCD Server 7.0.5.2 |
| 6.0.7 | February 11th, 2020 | ucds: 7.0.5.1.1044461 | Rollback of previous versions of UCD server not supported | Support for UCD Server 7.0.5.1 |
| 6.0.6 | January 14th, 2020 | ucds: 7.0.5.0.1041488 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.5.0 |
| 6.0.5 | December 4th, 2019 | ucds: 7.0.4.2.1038002 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.4.2 |
| 6.0.4 | November 5th, 2019 | ucds: 7.0.4.1.1036185 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.4.1 |
| 5.0.3 | October 1st, 2019 | ucds: 7.0.4.0.1034011 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.4.0 |
| 5.0.1 | September 3rd, 2019 | ucds: 7.0.3.3.1031820 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.3.3 |
| 5.0.0 | August 6th, 2019 | ucds: 7.0.3.2.1028848 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.3.2 |
| 4.1.2 | July 2nd, 2019 | ucds: 7.0.3.1.1026877 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.3.1 |
| 4.1.1 | June 11th, 2019 | ucds: 7.0.3.0.1025086 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.3.0 |
| 4.0.1 | May 7th, 2019 | ucds: 7.0.2.3.1021487 | Rollback to previous versions of UCD server not supported | Support for UCD Server 7.0.2.3 |
| 3.1.2 | February 5th, 2019 | ucds: 7.0.2.0.1011801, 7.0.1.2.1008304, 7.0.1.0.997822 | None | Support for UCD 7.0.2.0 |
| 3.1.1 | December 18th, 2018 | ucds: 7.0.1.2.1008304, 7.0.1.0.997822 | None | Run as non-root, allow non-secure connections to UCD Server, defect fixes |
| 3.0.0 | September 25, 2018 | ucds: 7.0.1.0.997822, 7.0.0.0.982083, 6.2.7.1.ifix02.973221 | None | Add support for HA clusters |
| 2.0.0 | June 19, 2018| ucds: 7.0.0.0.982083, 6.2.7.1.ifix02.973221 | None | Adds support for persisting log files, Adds support for Power LE platforms (UrbanCode Deploy 7.0.0.0 and later), Enables port 7919 for web agent communication (UrbanCode Deploy 7.0.0.0 and later)   |
| 1.0.0 | March 18, 2018| ucds: 6.2.7.1.ifix02.973221 | None | Initial Release  |

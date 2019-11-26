# ClangBuiltLinux Docker image with Qemu for arm

This is a fork of the ClangBuiltLinux Docker image with hacks to only include
the bits required for ARM.

It is used by this Travis CI job to build ASPEED kernels and boot them in Qemu:

 https://travis-ci.org/shenki/continuous-integration/

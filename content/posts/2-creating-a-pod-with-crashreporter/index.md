---
title: Creating a pod with PLCrashReporter
date: 2014-02-04T00:00:00+02:00
draft: false
---

Creating a pod which includes a framework can prove troublesome, this entry contains the findings after struggling to create a working pod that uses [PLCrashReporter](https://www.plcrashreporter.org/).

## Pod with frameworks
A normal pod using a standard-provided-by-apple framework such as QuartzCore adds its framework needs like the following.

```ruby
Pod::Spec.new do |s|
  s.name = 'MyPod'
  s.version = '1.0'
  s.authors = {'Your Name Here' => 'you@example.com'}
  s.homepage = 'http://www.example.com'
  s.summary = 'My pod is awesome'
  s.source = {:git => 'https://git.example.com/MyPodRepo', :revision => '1e16eee5c4e2'}
  s.platform = :ios
  s.source_files =  'MyPodSubdir/**/*.{h,m}'
  s.frameworks = 'QuartzCore'
end
```

CocoaPods takes care of everything in this case.

## Pod with vendor frameworks
One might wish to use a framework-not-provided-by-apple such as PLCrashReporter in a pod. In case you have looked at the documentation, you may have found the `vendored_frameworks` keyword and thought that was all that was needed.

The information that you do not seem to find in the documentation are:

- `vendored_frameworks` is the path in your source repo to the framework folder
- `xcconfig` should be used to add `LD_RUNPATH_SEARCH_PATHS` so `xcodebuild` understand where to find the framework
- `preserve_paths` should be used so the contents of the framework is not cleaned(deleted) by CocoaPods
- `resource` should be used to indicate that the framework will used as a bundle

The above bits of information was mostly found in [issue #58](https://github.com/CocoaPods/Core/issues/58) for CocoaPods. Using these bits of information you can include PLCrashReporter like the following.

```ruby
Pod::Spec.new do |s|
  s.name = 'MyPod'
  s.version = '1.0'
  s.authors = {'Your Name Here' => 'you@example.com'}
  s.homepage = 'http://www.example.com'
  s.summary = 'My pod is awesome'
  s.source = {:git => 'https://git.example.com/MyPodRepo', :revision => '1e16eee5c4e2'}
  s.platform = :ios
  s.source_files =  'MyPodSubdir/**/*.{h,m}'
  s.frameworks = 'QuartzCore'
  s.ios.preserve_paths = 'MyPodSubdir/Externals/*.framework'
  s.ios.vendored_frameworks = 'MyPodSubdir/Externals/CrashReporter.framework'
  s.ios.resource = 'MyPodSubdir/Externals/CrashReporter.framework'
  s.ios.xcconfig = { 'LD_RUNPATH_SEARCH_PATHS' => '"$(PODS_ROOT)/MyPod/MyPodSubdir/Externals"' }
end
```

It may only be needed to add one of the `preserve_paths` and `resource` keywords however this was not confirmed before ending the exploration into pods and podspec.


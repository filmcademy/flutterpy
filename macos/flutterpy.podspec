#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutterpy.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutterpy'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter package that provides seamless integration with Python.'
  s.description      = <<-DESC
A Flutter package that provides seamless integration with Python. FlutterPy automatically creates a Python environment and makes Python functions accessible from Dart.
                       DESC
  s.homepage         = 'https://github.com/yourusername/flutterpy'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  # Python-specific resources and files
  s.resource_bundles = {
    'flutterpy' => ['Resources/**/*']
  }
  
  # Added to ensure proper linkage with Python
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(CONFIGURATION_BUILD_DIR)',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/../Frameworks',
    'OTHER_LDFLAGS' => '$(inherited) -framework "Cocoa"',
    'MACOSX_DEPLOYMENT_TARGET' => '10.15'
  }

  s.platform = :osx, '10.15'
  s.swift_version = '5.0'
end 
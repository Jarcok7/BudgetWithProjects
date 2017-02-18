# Uncomment this line to define a global platform for your project
platform :ios, '8.0'
use_frameworks!

target 'BudgetWithProjects' do

  # Pods for BudgetWithProjects
  # pod 'CSVImporter', '~> 1.3'
  pod 'CSVImporter', :git => 'https://github.com/Flinesoft/CSVImporter.git'
  # pod 'CSV.swift', '~> 1.0'
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '3.0'
          end
      end
  end

end

platform :ios, '7.0'

#pod 'AFNetworking'
pod 'ActionSheetPicker-3.0'
pod 'ALAssetsLibrary-CustomPhotoAlbum'
pod 'CCHMapClusterController'
pod 'Crashlytics'
pod 'DateTools'
#pod 'DNTutorial'
#pod 'EAIntroView'
pod 'Fabric'
pod 'FastttCamera/Filters'
pod 'FBSDKCoreKit'
pod 'FBSDKLoginKit'
pod 'FBSDKShareKit'
pod 'Google/Analytics'
pod 'GoogleIDFASupport'
pod 'GPUImage'
#pod 'GVPhotoBrowser'
pod 'ImageEffects'
#pod 'MHVideoPhotoGallery'
pod 'NYXImagesKit', :git => 'https://github.com/Nyx0uf/NYXImagesKit.git'
pod 'Parse'
#pod 'ParseCrashReporting'
pod 'ParseFacebookUtilsV4'
pod 'Reachability'
#pod 'RMUniversalAlert'
pod 'SDCAlertView'
pod 'SDWebImage'
pod 'TSMessages'
#pod 'TutorialKit'
pod 'UIActivityIndicator-for-SDWebImage'
#pod 'UIPhotoGallery'

post_install do | installer |
    # Remove unused translations
    supported_locales = ['base', 'en', 'pt']
    Dir.glob(File.join('Pods', '**', '*.lproj')).each do |bundle|
        if (!supported_locales.include?(File.basename(bundle, ".lproj").downcase))
            puts "Removing #{bundle}"
            FileUtils.rm_rf(bundle)
        end
    end
    # Acknowledgements
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Fashion-Now/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

#target :Fashion-NowTests, :exclusive => true do
  # pod 'Kiwi'
#end

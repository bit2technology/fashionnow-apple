platform :ios, '7.0'

#pod 'AFNetworking'
pod 'ActionSheetPicker-3.0'
pod 'ALAssetsLibrary-CustomPhotoAlbum'
pod 'Bolts'
pod 'CCHMapClusterController'
#pod 'CRToast'
pod 'DateTools'
#pod 'DBCamera'
#pod 'DNTutorial'
#pod 'EAIntroView'
#pod 'Facebook-iOS-SDK'
pod 'FastttCamera/Filters', :git => 'https://github.com/IFTTT/FastttCamera.git'
pod 'FBSDKCoreKit'
pod 'FBSDKLoginKit'
pod 'FBSDKShareKit'
#pod 'FormatterKit'
pod 'Google/Analytics'
pod 'GPUImage', :git => 'https://github.com/BradLarson/GPUImage.git'
#pod 'GVPhotoBrowser'
pod 'ImageEffects'
#pod 'JLToast'
#pod 'LBBlurredImage'
#pod 'MHVideoPhotoGallery'
pod 'NYXImagesKit', :git => 'https://github.com/Nyx0uf/NYXImagesKit.git'
pod 'Parse'
pod 'ParseCrashReporting'
pod 'ParseFacebookUtilsV4'
pod 'Reachability'
pod 'SDCAlertView'
pod 'SDWebImage'
#pod 'StaticDataTableViewController'
#pod 'TGCameraViewController'
#pod 'Toast'
pod 'TSMessages'
#pod 'TutorialKit'
pod 'UIActivityIndicator-for-SDWebImage'
#pod 'UIPhotoGallery'

pre_install do |installer|
    supported_locales = ['base', 'en', 'pt']
    installer.pods.each do |pod|
        Dir.glob(File.join(pod.root, '**', '*.lproj')).each do |bundle|
            if (!supported_locales.include?(File.basename(bundle, ".lproj").downcase))
                puts "Removing #{bundle}"
                FileUtils.rm_rf(bundle)
            end
        end
    end
end

post_install do | installer |
    # Acknowledgements
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Fashion-Now/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

#target :Fashion-NowTests, :exclusive => true do
  # pod 'Kiwi'
#end

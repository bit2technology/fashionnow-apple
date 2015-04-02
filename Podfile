platform :ios, '7.0'

#pod 'AFNetworking'
pod 'ActionSheetPicker-3.0'
pod 'ALAssetsLibrary-CustomPhotoAlbum'
pod 'Bolts'
pod 'CRToast'
pod 'DateTools'
#pod 'DBCamera'
#pod 'DNTutorial'
pod 'Facebook-iOS-SDK'
#pod 'FormatterKit'
#pod 'GVPhotoBrowser'
#pod 'JLToast'
#pod 'MHVideoPhotoGallery'
#pod 'NYXImagesKit'
pod 'Parse'
pod 'ParseCrashReporting'
pod 'ParseFacebookUtils'
pod 'Reachability'
pod 'SDWebImage'
#pod 'StaticDataTableViewController'
#pod 'TGCameraViewController'
#pod 'Toast'
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

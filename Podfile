platform :ios, '7.0'

pod 'AFNetworking'
pod 'Bolts'
#pod 'DBCamera'
pod 'Facebook-iOS-SDK'
#pod 'MHVideoPhotoGallery'
#pod 'NYXImagesKit'
pod 'Parse'
pod 'ParseFacebookUtils'
pod 'SDWebImage'
pod 'StaticDataTableViewController'
pod 'TGCameraViewController'
pod 'UIActivityIndicator-for-SDWebImage'
#pod 'UIPhotoGallery'

post_install do | installer |
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Fashion Now/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

#target :Fashion NowTests, :exclusive => true do
  # pod 'Kiwi'
#end

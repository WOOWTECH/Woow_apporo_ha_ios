use_frameworks!
inhibit_all_warnings!

project 'HomeAssistant', 'Debug' => :debug, 'Release' => :release

def support_modules
  pod 'SwiftGen', '~> 6.5.0'
  pod 'SwiftLint', '0.54.0' # also update ci.yml GHA
  pod 'SwiftFormat/CLI', '0.53.1' # also update ci.yml GHA
end

if ENV['ONLY_SUPPORT_MODULES']
  # some of our CI scripts only need e.g. SwiftLint
  # this allows us to skip a lot of installation when unnecessary
  platform :ios, '15.0'
  support_modules
  workspace 'abstract.workspace'

  return self # rubocop:disable Lint/TopLevelReturnWithArgument
end

plugin 'cocoapods-acknowledgements'

pod 'Communicator', git: 'https://github.com/zacwest/Communicator.git', branch: 'observation-memory-direct'
pod 'ObjectMapper', git: 'https://github.com/tristanhimmelman/ObjectMapper.git', branch: 'master'
pod 'PromiseKit', '~> 8.1.1'

# Pinned to a version that ships PrivacyInfo.xcprivacy. RealmSwift is on Apple's list of SDKs
# that must carry a privacy manifest (developer.apple.com/support/third-party-SDK-requirements),
# and 10.35.0 predates it: uploading with that version fails as ITMS-91061. Kept inside 10.x so
# the API the app uses does not move.
pod 'RealmSwift', '~> 10.54'
pod 'Version'
pod 'XCGLogger'

# Keep Starscream reference even though HAKit already install it, because it defines our fork with the necessary fix
pod 'Starscream', git: 'https://github.com/bgoncal/starscream', tag: '4.0.9'
pod 'HAKit', git: 'https://github.com/home-assistant/HAKit.git', tag: '0.4.16'
pod 'HAKit/Mocks', git: 'https://github.com/home-assistant/HAKit.git', tag: '0.4.16'
pod 'HAKit/PromiseKit', git: 'https://github.com/home-assistant/HAKit.git', tag: '0.4.16'

def test_pods
  pod 'OHHTTPStubs/Swift'
end

def shared_fwk_pods
  pod 'Sodium', git: 'https://github.com/zacwest/swift-sodium.git', branch: 'xcode-14.0.1'
end

abstract_target 'iOS' do
  platform :ios, '15.0'

    # MBProgressHUD is on Apple's privacy-manifest list, but 1.2.0 is the newest release there
  # is and it ships no manifest - there is nothing to upgrade to. Handled in post_install
  # below, which writes one into the pod's resource bundle. See PRIVACY-MANIFESTS.md.
  pod 'MBProgressHUD', '~> 1.2.0'
    # Builds Reachability.framework, which is on Apple's list. 5.2.x ships the privacy manifest.
  pod 'ReachabilitySwift', '~> 5.2'

  # fixes newer cocoapods search path issues for Clibsodium build failures
  shared_fwk_pods

  target 'Shared-iOS' do
    shared_fwk_pods

    target 'Tests-Shared' do
      inherit! :complete
      test_pods
    end
  end

  target 'App' do
    pod 'CPDAcknowledgements', git: 'https://github.com/CocoaPods/CPDAcknowledgements', branch: 'master'

    support_modules

    target 'Tests-App' do
      inherit! :search_paths
      test_pods
    end
  end

  target 'SharedTesting'
  target 'Extensions-Intents'
  target 'Extensions-NotificationContent'
  target 'Extensions-NotificationService'
  target 'Extensions-Share'
  target 'Extensions-Widgets'
end

abstract_target 'watchOS' do
  platform :watchos, '8.0'

  target 'Shared-watchOS' do
    shared_fwk_pods
  end

  target 'WatchExtension-Watch'
end

post_install do |installer|
  # --- Vendored privacy manifests -------------------------------------------------------
  # Apple requires a PrivacyInfo.xcprivacy for every SDK on its third-party list. Pods that
  # ship their own are left alone; the ones below have no release that carries one, so we
  # supply it. Each file states what was verified about that pod - read it before trusting it.
  #
  # Dropping a pod from this map is only safe once its own release carries a manifest; check
  # with:  find Pods/<Pod> -name '*.xcprivacy'
  # The file MUST be named PrivacyInfo.xcprivacy in the bundle - Apple looks for that exact
  # name - so each pod gets its own directory rather than a name-prefixed file.
  vendored_manifests = {
    'MBProgressHUD' => 'Configuration/VendoredPrivacyManifests/MBProgressHUD/PrivacyInfo.xcprivacy',
  }
  vendored_manifests.each do |pod_name, source_path|
    target = installer.pods_project.targets.find { |t| t.name == pod_name }
    next unless target

    if Dir.glob("Pods/#{pod_name}/**/*.xcprivacy").any?
      Pod::UI.puts "[privacy] #{pod_name} now ships its own manifest - drop it from " \
                   'vendored_manifests in the Podfile'
      next
    end

    abs = File.expand_path(source_path, __dir__)
    raise "Missing vendored privacy manifest: #{source_path}" unless File.exist?(abs)

    group = installer.pods_project.main_group.find_subpath('VendoredPrivacyManifests', true)
    ref = group.files.find { |f| f.path == abs } ||
          group.new_file(abs)
    unless target.resources_build_phase.files_references.include?(ref)
      target.resources_build_phase.add_file_reference(ref)
      Pod::UI.puts "[privacy] vendored a manifest into #{pod_name}"
    end
  end
  # --------------------------------------------------------------------------------------

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '8.0'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'

      config.build_settings['SWIFT_INSTALL_OBJC_HEADER'] = 'NO' unless target.name.include? 'Firebase'

      next unless config.name == 'Release'

      # cocoapods defaults to not stripping the frameworks it creates
      config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'YES'
    end

    # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
    # (catalyst fix)
    # rubocop:disable Style/Next
    if target.respond_to?(:product_type) && (target.product_type == 'com.apple.product-type.bundle')
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGN_IDENTITY[sdk=macosx*]'] = '-'
        config.build_settings['CODE_SIGNING_ALLOWED[sdk=iphoneos*]'] = 'NO'
      end
    end
    # rubocop:enable Style/Next
  end
end

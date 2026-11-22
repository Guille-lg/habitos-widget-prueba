"""Generate the two-target Xcode project with the Python standard library."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent
objects = {}

def uid(name):
    return hashlib.sha1(name.encode()).hexdigest().upper()[:24]

def add(name, text):
    objects[uid(name)] = text
    return uid(name)

def q(value):
    return json.dumps(value, ensure_ascii=False)

def array(values):
    return '(' + ', '.join(values) + ',)'

def obj(kind, **fields):
    return '{ isa = ' + kind + '; ' + ' '.join(f'{key} = {value};' for key, value in fields.items()) + ' }'

shared = ['Shared/WaterLedger.swift', 'Shared/SharedStorage.swift', 'Shared/WaterIntents.swift']
app_sources = ['App/HabitosApp.swift'] + shared
widget_sources = ['Widget/WaterWidget.swift'] + shared
files = list(dict.fromkeys(app_sources + widget_sources))
for file in files:
    add(file, obj('PBXFileReference', lastKnownFileType='sourcecode.swift', path=q(file), sourceTree='"<group>"'))
add('assets', obj('PBXFileReference', lastKnownFileType='folder.assetcatalog', path=q('App/Assets.xcassets'), sourceTree='"<group>"'))
add('app-product', obj('PBXFileReference', explicitFileType='wrapper.application', path='Habitos.app', sourceTree='BUILT_PRODUCTS_DIR'))
add('widget-product', obj('PBXFileReference', explicitFileType='"wrapper.app-extension"', path='AguaWidget.appex', sourceTree='BUILT_PRODUCTS_DIR'))
add('products', obj('PBXGroup', children=array([uid('app-product'), uid('widget-product')]), name='Products', sourceTree='"<group>"'))
add('root-group', obj('PBXGroup', children=array([uid(f) for f in files] + [uid('assets'), uid('products')]), sourceTree='"<group>"'))

for target, sources in [('app', app_sources), ('widget', widget_sources)]:
    for file in sources:
        add(target + ':' + file, obj('PBXBuildFile', fileRef=uid(file)))
    add(target + '-sources', obj('PBXSourcesBuildPhase', buildActionMask='2147483647', files=array([uid(target + ':' + f) for f in sources]), runOnlyForDeploymentPostprocessing='0'))
    add(target + '-frameworks', obj('PBXFrameworksBuildPhase', buildActionMask='2147483647', files='()', runOnlyForDeploymentPostprocessing='0'))
    resources = []
    if target == 'app':
        resources.append(add('asset-build', obj('PBXBuildFile', fileRef=uid('assets'))))
    add(target + '-resources', obj('PBXResourcesBuildPhase', buildActionMask='2147483647', files=array(resources) if resources else '()', runOnlyForDeploymentPostprocessing='0'))

add('embed-widget', obj('PBXBuildFile', fileRef=uid('widget-product'), settings='{ ATTRIBUTES = (RemoveHeadersOnCopy,); }'))
add('embed-phase', obj('PBXCopyFilesBuildPhase', buildActionMask='2147483647', dstPath='""', dstSubfolderSpec='13', files=array([uid('embed-widget')]), name='"Embed App Extensions"', runOnlyForDeploymentPostprocessing='0'))
add('widget-proxy', obj('PBXContainerItemProxy', containerPortal=uid('project'), proxyType='1', remoteGlobalIDString=uid('widget-target'), remoteInfo='AguaWidget'))
add('widget-dependency', obj('PBXTargetDependency', target=uid('widget-target'), targetProxy=uid('widget-proxy')))

for owner in ['project', 'app', 'widget']:
    for config in ['Debug', 'Release']:
        values = {
            'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'SWIFT_VERSION': '5.0',
            'TARGETED_DEVICE_FAMILY': '1', 'SDKROOT': 'iphoneos',
            'CLANG_ENABLE_MODULES': 'YES', 'SWIFT_STRICT_CONCURRENCY': 'minimal',
            'CODE_SIGN_STYLE': 'Automatic',
            'SUPPORTED_PLATFORMS': '"iphoneos iphonesimulator"',
            'SUPPORTS_MACCATALYST': 'NO', 'SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD': 'NO',
            'SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD': 'NO',
            'SWIFT_OPTIMIZATION_LEVEL': '"-Onone"' if config == 'Debug' else '"-O"',
        }
        if owner != 'project':
            values.update({
                'INFOPLIST_FILE': q(f'Configuration/{"App" if owner == "app" else "Widget"}-Info.plist'),
                'CODE_SIGN_ENTITLEMENTS': 'Configuration/Habitos.entitlements',
                'PRODUCT_BUNDLE_IDENTIFIER': 'org.habitlab.watertrial' + ('.widget' if owner == 'widget' else ''),
                'PRODUCT_NAME': 'Habitos' if owner == 'app' else 'AguaWidget',
                'LD_RUNPATH_SEARCH_PATHS': q('$(inherited) @executable_path/Frameworks' + (' @executable_path/../../Frameworks' if owner == 'widget' else '')),
            })
            if owner == 'widget':
                values.update({'APPLICATION_EXTENSION_API_ONLY': 'YES', 'SKIP_INSTALL': 'YES'})
            else:
                values['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
        settings = '{ ' + ' '.join(f'{k} = {v};' for k, v in values.items()) + ' }'
        add(owner + '-' + config, obj('XCBuildConfiguration', buildSettings=settings, name=config))
    add(owner + '-configs', obj('XCConfigurationList', buildConfigurations=array([uid(owner + '-Debug'), uid(owner + '-Release')]), defaultConfigurationIsVisible='0', defaultConfigurationName='Release'))

for target, product, product_type, name in [('app', 'app-product', 'application', 'Habitos'), ('widget', 'widget-product', 'app-extension', 'AguaWidget')]:
    phases = [uid(target + '-sources'), uid(target + '-frameworks'), uid(target + '-resources')]
    if target == 'app': phases.append(uid('embed-phase'))
    add(target + '-target', obj('PBXNativeTarget', buildConfigurationList=uid(target + '-configs'), buildPhases=array(phases), buildRules='()', dependencies=array([uid('widget-dependency')]) if target == 'app' else '()', name=name, productName=name, productReference=uid(product), productType=q('com.apple.product-type.' + product_type)))

add('project', obj('PBXProject', attributes='{ LastUpgradeCheck = 2600; }', buildConfigurationList=uid('project-configs'), compatibilityVersion='"Xcode 14.0"', developmentRegion='es', hasScannedForEncodings='0', knownRegions='(es, en, Base,)', mainGroup=uid('root-group'), productRefGroup=uid('products'), projectDirPath='""', projectRoot='""', targets=array([uid('app-target'), uid('widget-target')])))
project = ROOT / 'Habitos.xcodeproj'
project.mkdir(exist_ok=True)
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(f'{key} = {value};' for key, value in objects.items()) + '\n}; rootObject = ' + uid('project') + '; }\n', encoding='utf-8')
scheme_dir = project / 'xcshareddata' / 'xcschemes'
scheme_dir.mkdir(parents=True, exist_ok=True)
(scheme_dir / 'Habitos.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
   <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('app-target')}" BuildableName="Habitos.app" BlueprintName="Habitos" ReferencedContainer="container:Habitos.xcodeproj"/>
  </BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug"/>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
  <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('app-target')}" BuildableName="Habitos.app" BlueprintName="Habitos" ReferencedContainer="container:Habitos.xcodeproj"/></BuildableProductRunnable>
 </LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"/>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''', encoding='utf-8')
print('Generated Habitos.xcodeproj (iPhone app + WidgetKit extension).')

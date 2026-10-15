from pathlib import Path
import hashlib
root=Path(__file__).resolve().parents[1]
def ID(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
objects=[]
def add(key, body): objects.append(f'{ID(key)} = {{ {body} }};'); return ID(key)
def arr(v): return '('+', '.join(v)+')'
files={}; builds={}
for folder in ['Bloom','BloomTests','BloomUITests']:
    refs=[]; src=[]; res=[]
    for path in sorted((root/folder).iterdir()):
        if not path.is_file() and path.suffix != ".xcassets": continue
        ext=path.suffix
        typ={'.swift':'sourcecode.swift','.plist':'text.plist.xml','.xcprivacy':'text.xml','.xcassets':'folder.assetcatalog'}.get(ext,'text')
        ref=add(str(path.relative_to(root)),f'isa = PBXFileReference; lastKnownFileType = {typ}; path = "{path.name}"; sourceTree = "<group>";')
        refs.append(ref)
        if ext in ['.swift','.xcprivacy','.xcassets']:
            b=add('build'+folder+path.name,f'isa = PBXBuildFile; fileRef = {ref};')
            (src if ext=='.swift' else res).append(b)
    files[folder]=add('group'+folder,f'isa = PBXGroup; children = {arr(refs)}; path = {folder}; sourceTree = "<group>";')
    builds[folder]=(src,res)
products=[]; targets=[]
for name in ['Bloom','BloomTests','BloomUITests']:
    product=name+('.app' if name=='Bloom' else '.xctest')
    pref=add('product'+name,f'isa = PBXFileReference; explicitFileType = {"wrapper.application" if name=="Bloom" else "wrapper.cfbundle"}; path = {product}; sourceTree = BUILT_PRODUCTS_DIR;')
    products.append(pref)
    phases=[]
    for phase, contents in [('Sources',builds[name][0]),('Resources',builds[name][1]),('Frameworks',[])]:
        phases.append(add(phase+name,f'isa = PBX{phase}BuildPhase; buildActionMask = 2147483647; files = {arr(contents)}; runOnlyForDeploymentPostprocessing = 0;'))
    cfgs=[]
    for config in ['Debug','Release']:
        settings={'PRODUCT_NAME':'"$(TARGET_NAME)"','PRODUCT_BUNDLE_IDENTIFIER':f'com.bloom.private.{name.lower()}', 'SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','TARGETED_DEVICE_FAMILY':'1','SDKROOT':'iphoneos','CODE_SIGN_STYLE':'Automatic','SWIFT_EMIT_LOC_STRINGS':'YES'}
        if name=='Bloom': settings.update({'INFOPLIST_FILE':'Bloom/Info.plist','GENERATE_INFOPLIST_FILE':'NO','SUPPORTED_PLATFORMS':'"iphoneos iphonesimulator"','ENABLE_PREVIEWS':'YES','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon'})
        else:
            settings['GENERATE_INFOPLIST_FILE']='YES'
            if name=='BloomTests': settings.update({'TEST_HOST':'"$(BUILT_PRODUCTS_DIR)/Bloom.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Bloom"','BUNDLE_LOADER':'"$(TEST_HOST)"'})
            else: settings['TEST_TARGET_NAME']='Bloom'
        if config=='Debug': settings.update({'SWIFT_OPTIMIZATION_LEVEL':'"-Onone"','ENABLE_TESTABILITY':'YES','DEBUG_INFORMATION_FORMAT':'dwarf'})
        else: settings.update({'SWIFT_OPTIMIZATION_LEVEL':'"-O"','DEBUG_INFORMATION_FORMAT':'"dwarf-with-dsym"'})
        cfgs.append(add(name+config,'isa = XCBuildConfiguration; name = '+config+'; buildSettings = {'+' '.join(f'{k} = {v};' for k,v in settings.items())+'};'))
    cl=add('configs'+name,f'isa = XCConfigurationList; buildConfigurations = {arr(cfgs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    deps=[]
    if name!='Bloom':
        proxy=add('proxy'+name,f'isa = PBXContainerItemProxy; containerPortal = {ID("project")}; proxyType = 1; remoteGlobalIDString = {ID("targetBloom")}; remoteInfo = Bloom;')
        deps=[add('dependency'+name,f'isa = PBXTargetDependency; target = {ID("targetBloom")}; targetProxy = {proxy};')]
    ptype='com.apple.product-type.'+('application' if name=='Bloom' else 'bundle.unit-test' if name=='BloomTests' else 'bundle.ui-testing')
    targets.append(add('target'+name,f'isa = PBXNativeTarget; buildConfigurationList = {cl}; buildPhases = {arr(phases)}; buildRules = (); dependencies = {arr(deps)}; name = {name}; productName = {name}; productReference = {pref}; productType = "{ptype}";'))
prodgroup=add('products',f'isa = PBXGroup; children = {arr(products)}; name = Products; sourceTree = "<group>";')
main=add('main',f'isa = PBXGroup; children = {arr(list(files.values())+[prodgroup])}; sourceTree = "<group>";')
pc=[]
for config in ['Debug','Release']:
    pc.append(add('project'+config,f'isa = XCBuildConfiguration; name = {config}; buildSettings = {{ CLANG_ENABLE_MODULES = YES; SWIFT_STRICT_CONCURRENCY = targeted; }};'))
cl=add('projectconfigs',f'isa = XCConfigurationList; buildConfigurations = {arr(pc)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
add('project',f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; BuildIndependentTargetsInParallel = YES; }}; buildConfigurationList = {cl}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {main}; productRefGroup = {prodgroup}; projectDirPath = ""; projectRoot = ""; targets = {arr(targets)};')
(root/'Bloom.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {ID("project")}; }}\n')
def ref(name): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ID("target"+name)}" BuildableName="{name}{".app" if name=="Bloom" else ".xctest"}" BlueprintName="{name}" ReferencedContainer="container:Bloom.xcodeproj"/>'
scheme=f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref('Bloom')}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref('BloomTests')}</TestableReference><TestableReference skipped="NO">{ref('BloomUITests')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('Bloom')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('Bloom')}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
(root/'Bloom.xcodeproj/xcshareddata/xcschemes/Bloom.xcscheme').write_text(scheme)

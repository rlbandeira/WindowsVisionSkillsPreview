param($TargetDir,$Arch,$ProjectDir,$VCInstallDir,[switch] $Debug)
[xml]$packages = Get-Content "$ProjectDir\packages.config"
echo "Gathering known dependencies..."

foreach ($package in $packages.packages.package)
{
    $packageroot = "$ProjectDir" + "..\packages\" + $package.id + "." + $package.version
    $dllPath = $packageroot + "\runtimes\win10-" + $Arch
    $dllFiles = Get-ChildItem -Path "$dllPath" -Recurse -Filter *.dll -File | %{$_.FullName}
    foreach($file in $dllFiles) 
    {
        copy -Force $file $TargetDir
    }

    $manifestPath = $packageroot +"\lib\uap10.0.17763\"
    if(!(Test-Path $manifestPath))
    {
        $manifestPath = $packageroot +"\lib\uap10.0\"
    }
    
    $manifestFiles = Get-ChildItem -Path "$manifestPath" -Recurse -Filter *.manifest -File | %{$_.FullName}
    foreach($file in $manifestFiles) 
    {
    
        copy -Force $file $TargetDir
    }

    if(Test-Path "$packageroot\contentFiles")
    {
    
        $contentFiles = Get-ChildItem -Path "$packageroot\contentFiles\" -Recurse -Filter *.* -File | %{$_.FullName}
        foreach($file in $contentFiles)
        {
            copy -Force $file $TargetDir
        }
    }

}
$redistfiles =@("vcruntime140" , "msvcp140")
$redistPath = $VCInstallDir + "Redist\MSVC\14.16.27012\onecore\$Arch\Microsoft.VC141.CRT\"
if($Debug)
{
    $redistPathDebug = $VCInstallDir + "Redist\MSVC\14.16.27012\onecore\debug_nonredist\$Arch\Microsoft.VC141.DebugCRT\"
    foreach($file in $redistfiles)
    {
        $fullpath = $redistPathDebug + $file +"d.dll"
        copy -Force $fullpath $TargetDir
    }
}

#*_app.dll symlinks for the skills which are built with the APPCONTAINER flag, assuming skills are all in Release mode only
foreach($file in $redistfiles)
{
    $fullname = $file + ".dll"
    $linkFile = $file + "_app.dll"
    $fullpath = $redistPath+$fullname
    copy -Force $fullpath $TargetDir

    cmd /c mklink /h $TargetDir$linkFile $TargetDir$fullname
}

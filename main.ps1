$vu= #vShpere Username
$vp= #vSphere Password
$vs= #vSphere Server
#$outfile = "C:\Test\sstest\test.txt"
Connect-VIServer -Server $vs -User $vu -Password $vp
$SlURL = #Slack API URL
$date = Get-Date
$date = $date.AddDays(-5)


$Headers = @{
    channel = #Slack Channel Code
    Authorization = #Slack Auth Key
    "Content-Type" = "application/json"
    }

$slReq = [ordered]@{
"channel" = #Slack Channel Code
"blocks" = @(
)
}    

$snapshotdeets = Get-VM | Get-Snapshot | Select VM,Name,Created,SizeGB

$SSCount = 0

if ($snapshotdeets.vm.length -gt 0){
    $carol = $snapshotdeets.vm.Length
    $addTitle =@{
    "type" = "section"
    "block_id" = "section0"
    "text" = @{
    type = "mrkdwn"
    text = "*" + $carol + " snapshots found*"
        }
    }
    $slReq.blocks += $addTitle
    foreach($snapshot in $snapshotdeets){
        $SSCount ++
        $snapshotVM = $snapshot.VM.name
        $snapshotName = $snapshot.Name
        $snapshotCreated = $snapshot.Created
        $snapshotSize = [math]::Round($snapshot.SizeGB, 2)
        $sizeMetric = "GB"
        $sizeWarn = ":red_circle:"
            if($snapshot.SizeGB -lt 1){
                $snapshotSizeMB = Get-Snapshot -VM $snapshotVM -Name $snapshotName | Select SizeMB
                $snapshotSize = [math]::Round($snapshotSizeMB.SizeMB, 2)
                $sizeMetric = "MB"
                $sizeWarn = ":white_circle:"
        }
            if($snapshotCreated -lt $date){
                $dateWarn = ":red_circle:"} else
                {$dateWarn = ":white_circle:"}

        $VMDeets = Get-VM -Name $snapshotVM
        $VMID = $VMDeets.Id
        $VMID = $VMID -replace 'VirtualMachine-', 'VirtualMachine:'

        #"$snapshotVM $snapshotCreated $snapshotSize$sizeMetric" | Out-File -FilePath $outfile -Append
        $addToBlocks = @{
        "type" = "section"
        "block_id" = "section" + $SSCount
        "text" =@{
        type = "mrkdwn"
        text = $snapshotVM + " | " + $dateWarn + " " + $snapshotCreated + " | " + $sizeWarn + " " + $snapshotSize + " " + $sizeMetric
                }
            }
            $slReq.blocks += $addToBlocks
        }
    }


$JSON = $slReq | ConvertTo-Json -Depth 4
$slresult = Invoke-RestMethod -Method Post -Uri $SlUrl -Headers $Headers -Body $JSON

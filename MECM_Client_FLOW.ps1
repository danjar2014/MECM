<#

.Synopsis
    Check Ports

.Notes

    Version tracking
    1.0     - 27/01/2020 SLE
    2.0     - 23/03/2020 SLE
            - Add resolution IP/Hostname and Hostname/IP
            - Fix bug resolution DNSROOT
            - check IPV4 / IPV6
    2.1     - 27/03 SLE
            - Add New Version 1.5 of Log function
    2.2     - 03/04 SLE
            - Add affichage IP local

#>


######################################
#### Param utilisees in the script
######################################



#SCCM


##$dests_SCCM_MP = "10.243.70.24;10.118.160.172;10.243.73.3;10.118.171.48;10.243.78.8;10.118.171.49;10.243.78.31;10.118.171.50;10.243.78.69;10.118.171.51;10.243.78.70;10.118.171.52;10.243.78.87;10.118.171.62;10.118.171.57;10.94.59.39;10.94.59.80;10.94.59.86;10.94.59.106;10.94.59.239;10.94.59.240;10.94.58.11;10.94.59.165;10.94.59.244;10.94.59.245;10.94.59.246;10.94.59.247"
##$ports_SCCM_MP = "80;443;445;10123"

####$dests_SCCMFallbackDP = "10.94.58.80;10.94.59.152;10.94.59.3;10.94.58.80;10.94.59.152,10.94.59.3;10.118.175.175;10.118.175.177"
##$ports_SCCMFallbackDP = "80;443;445;10123

$dests_SCCM_PXE_UDP = "10.118.175.175"
$ports_SCCM_PXE_UDP = "67;68;69;4011"

##$dests_SCCMFallbackStatus = "10.94.58.41;10.118.140.208;10.118.138.149"
##$ports_SCCMFallbackStatus = "80;443;445;10123"

##$dests_SCCM_SUP = "10.94.59.250;10.94.58.58;10.243.70.24;10.118.160.172"
##$ports_SCCM_SUP = "80;443;8530;8531"

##$dests_SCCM_Web = "10.94.58.86;10.94.58.88;10.118.160.171;10.243.71.195;10.118.175.22;10.118.175.104;sccm-console.cib.echonet"
##$ports_SCCM_Web = "80;443;3389"

##$dests_SCCM_DP = "10.39.24.78"
##$ports_SCCM_DP = "80;443;8530;8531;445"

##$dests_SCCM_DP_UDP = "10.39.24.78"
##$ports_SCCM_DP_UDP = "67;68;69;4011"


######################################
#### Variables utilisées dans le script
######################################




$export_file = "test-port.txt"
$Log_f_file = "test-port.txt"

$v_Title = "Test ports"


$GLOBAL:IPv4RegexNew = '((?:(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)\.){3}(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d))'



##################################
# Import Module
##################################

##################################
# Fonctions
##################################


############### Fonction de Log Date + Affichage + Fichier de log - V1.5 - 05/02/20 ##################
Function Log_f
{
Param (
    [Parameter(Mandatory = $false)]
	[String]
    $data = "",
        
    [Parameter(Mandatory = $false)]
	[String]
    $color = "Gray",
    
    [Parameter(Mandatory = $false)]
	[Boolean]
    $NONewLigne = $false
    )

#  Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White
    
    $date_now = date
    If (!(test-path -path "$Log_f_file"))
        {
            $Log_f_file_item = New-item -type file $Log_f_file -force 
            set-content -path $Log_f_file_item -Value "# $date_now # New Log file..." -Encoding UTF8
        }
    else
        { $Log_f_file_item = $Log_f_file    }
  
    
    Write-host "" -ForegroundColor DarkGray -NoNewline
    If ($NONewLigne)
        { Write-host $data -ForegroundColor $color -NoNewline }
    Else
        { Write-host $data -ForegroundColor $color  }
    

   If ((Get-Item $Log_f_file_item).length -gt 6000kb)
    {
        
        $Log_f_file_temp = ".\$Log_f_file.tmp"
        $Log_f_file_item_temp = New-item -type file $Log_f_file_temp -force 
        
        $data = (get-content -path $Log_f_file_item -Encoding UTF8) | select -Skip 100  |Set-Content -path $Log_f_file_item_temp -Encoding UTF8
            
        Remove-Item $Log_f_file_item
        Rename-Item $Log_f_file_item_temp $Log_f_file_item
        Add-content -path $Log_f_file_item -Value "# $date_now # ... Rotation du fichier de Log ..." -Encoding UTF8
        
    }
  
   If ($NONewLigne)
    { $Global:V_New_Ligne = $Global:V_New_Ligne + $data  }
    Else
    {
            $Global:V_New_Ligne = "# $date_now #"+$Global:V_New_Ligne+$data
            Add-Content -path $Log_f_file_item -value $Global:V_New_Ligne -Encoding UTF8  
            $Global:V_New_Ligne = ""
    }

        
    
}



############### Fonction  test port ##################
  
Function test-port
{  
    Param(  
        [Parameter(  
            Mandatory = $True,  
            Position = 0,  
            ParameterSetName = '',  
            ValueFromPipeline = $True)]  
            [array]$computer,  
        [Parameter(  
            Position = 1,  
            Mandatory = $True,  
            ParameterSetName = '')]  
            [array]$port,  
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [int]$TCPtimeout=1000,  
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [int]$UDPtimeout=1000,             
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [switch]$TCP,  
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [switch]$UDP                                    
        )  
    Begin {  
        If (!$tcp -AND !$udp) {$tcp = $True}  
        #Typically you never do this, but in this case I felt it was for the benefit of the function  
        #as any errors will be noted in the output of the report          
        $ErrorActionPreference = "SilentlyContinue"  
        $report = @()  
    }  
    Process {     
        ForEach ($c in $computer) {  
            ForEach ($p in $port) {  
                If ($tcp) {    
                    #Create temporary holder   
                    $temp = "" | Select Server, Port, TypePort, Open, Notes  
                    #Create object for connecting to port on computer  
                    $tcpobject = new-Object system.Net.Sockets.TcpClient  
                    #Connect to remote machine's port                
                    $connect = $tcpobject.BeginConnect($c,$p,$null,$null)  
                    #Configure a timeout before quitting  
                    $wait = $connect.AsyncWaitHandle.WaitOne($TCPtimeout,$false)  
                    #If timeout  
                    If(!$wait) {  
                        #Close connection  
                        $tcpobject.Close()  
                        Write-Verbose "Connection Timeout"  
                        #Build report  
                        $temp.Open = $False 
                      
                    } Else {  
                        $error.Clear()  
                        $tcpobject.EndConnect($connect) | out-Null  
                        #If error  
                        If($error[0]){  
                            #Begin making error more readable in report  
                            [string]$string = ($error[0].exception).message  
                            $message = (($string.split(":")[1]).replace('"',"")).TrimStart()  
                            $failed = $true  
                        }  
                        #Close connection      
                        $tcpobject.Close()  
                        #If unable to query port to due failure  
                        If($failed){  
                            #Build report  
                            $temp.Open = $False 
                        } Else{  
                            #Build report  
                            $temp.Open = $True   
                        }  
                    }     
                    #Reset failed value  
                    $failed = $Null      
                    #Merge temp array with report              
                    $report += $temp  
                }      
                If ($udp) {  
                    #Create temporary holder   
                    $temp = "" | Select Server, Port, TypePort, Open, Notes                                     
                    #Create object for connecting to port on computer  
                    $udpobject = new-Object system.Net.Sockets.Udpclient
                    #Set a timeout on receiving message 
                    $udpobject.client.ReceiveTimeout = $UDPTimeout 
                    #Connect to remote machine's port                
                    Write-Verbose "Making UDP connection to remote server" 
                    $udpobject.Connect("$c",$p) 
                    #Sends a message to the host to which you have connected. 
                    Write-Verbose "Sending message to remote host" 
                    $a = new-object system.text.asciiencoding 
                    $byte = $a.GetBytes("$(Get-Date)") 
                    [void]$udpobject.Send($byte,$byte.length) 
                    #IPEndPoint object will allow us to read datagrams sent from any source.  
                    Write-Verbose "Creating remote endpoint" 
                    $remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0) 
                    Try { 
                        #Blocks until a message returns on this socket from a remote host. 
                        Write-Verbose "Waiting for message return" 
                        $receivebytes = $udpobject.Receive([ref]$remoteendpoint) 
                        [string]$returndata = $a.GetString($receivebytes)
                        If ($returndata) {
                           Write-Verbose "Connection Successful"  
                            #Build report  
                            $temp.Open = $True 
                            $udpobject.close()   
                        }                       
                    } Catch { 
                        If ($Error[0].ToString() -match "\bRespond after a period of time\b") { 
                            #Close connection  
                            $udpobject.Close()  
                            #Make sure that the host is online and not a false positive that it is open 
                            If (Test-Connection -comp $c -count 1 -quiet) { 
                                Write-Verbose "Connection Open"  
                                #Build report  
                                $temp.Open = $True 
                            } Else { 
                                <# 
                                It is possible that the host is not online or that the host is online,  
                                but ICMP is blocked by a firewall and this port is actually open. 
                                #> 
                                Write-Verbose "Host maybe unavailable"  
                                #Build report  
                                $temp.Open = $False 
                            }                         
                        } ElseIf ($Error[0].ToString() -match "forcibly closed by the remote host" ) { 
                            #Close connection  
                            $udpobject.Close()  
                            Write-Verbose "Connection Timeout"  
                            #Build report  
                            $temp.Open = $False 
                        } Else {                      
                            $udpobject.close() 
                        } 
                    }     
                    #Merge temp array with report              
                    $report = $temp  
                }                                  
            }  
        }                  
    }  
    End {  
        #Generate Report  
        Return $report.open
    }
}


############### Fonction  affichage ##################
  
Function F_Affichage 
{
Param (
    $name = "",
    $dests = "",
    $ports = "",
    $type =  "$False"
    
    )
Log_f " ==> $name <==" "Yellow"
Log_f (" ".PadRight(45)) "GRAY"  $true
Log_f (" ".PadRight(18)) "GRAY"  $true
foreach ($port in ($ports.split(";")) ){ Log_f  ("$port").PadRight(8) "White" $true } 
Log_f

$IPv4RegexNew = '((?:(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d)\.){3}(?:1\d\d|2[0-5][0-5]|2[0-4]\d|0?[1-9]\d|0?0?\d))'

foreach ($dest in ($dests.split(";")) ){

    if ($([regex]::Matches($dest, $IPv4RegexNew)))
    {
    
        Try {Log_f ( ((  $([System.net.dns]::GetHostByAddress($Dest)).Hostname) ).PadRight(45)) "White" $true}
        Catch {Log_f ("No DNS Resolution".PadRight(45)) "RED" $true}
        Log_f ($dest.PadRight(18)) "Gray" $true 

    }
    ELse
    {
        Log_f ("$Dest ".PadRight(45)) "Gray" $true
        Try {  
            $V_ip = $([System.Net.Dns]::GetHostAddresses($Dest).IPAddressToString)
            if ($([regex]::Matches($V_ip, $IPv4RegexNew)))
            { Log_f ($V_ip.PadRight(18)) "White" $true }
            Else
            { Log_f (( "No IP V4"  ).PadRight(18)) "RED"  ; continue}

            }
        Catch { Log_f (( "No IP"  ).PadRight(18)) "RED"  ; continue}
    }
    foreach ($port in ($ports.split(";")) ){
        if ($type) { $result = test-port $Dest $port -UDP }
        Else { $result = test-port $Dest $port}
        
        if ($result) { Log_f  ("$result").PadRight(8) "Green" $true }
        Else         { Log_f  ("$result").PadRight(8) "red" $true }
    }
    Log_f
}
Log_f
}

##################################
# Main
##################################

$V_debut = Get-date



Clear
Log_f 
Log_f 
Log_f 
Log_f "-------------------------------------------------------------" "Magenta"
Log_f "   $v_Title                                          " "Magenta"
Log_f "-------------------------------------------------------------" "Magenta"
Log_f 
Log_f

Log_f "-------------------------------------------------------------" "Yellow"

$V_IP_locals = Get-NetIPAddress -AddressFamily IPv4 |Where-object -FilterScript {($_.AddressState -Eq "Preferred") -and ($_.iPAddress -NE "127.0.0.1" )}

foreach ($V_IP_local in $V_IP_locals)
{
    Log_f ("IP local : ".Padleft(30))  "yellow" $true
    Log_f $V_IP_local.iPAddress "White"

}
Log_f "-------------------------------------------------------------" "Yellow"
Log_f 
Log_f





#SCCM

#SCCMF_Affichage "SCCM MPs" $Dests_SCCM_MP $ports_SCCM_MP $false

#SCCMF_Affichage "SCCM Fallback DP" $Dests_SCCMFallbackDP $ports_SCCMFallbackDP $false

F_Affichage "SCCM PXE UDP" $Dests_SCCM_PXE_UDP $ports_SCCM_PXE_UDP $true

#SCCMF_Affichage "SCCM Fallback Status" $Dests_SCCMFallbackStatus $ports_SCCMFallbackStatus $false

#SCCMF_Affichage "SCCM SUP" $Dests_SCCM_SUP $ports_SCCM_SUP $false

#SCCMF_Affichage "SCCM Web" $Dests_SCCM_Web $ports_SCCM_Web $false

#SCCMF_Affichage "SCCM DP" $Dests_SCCM_DP $ports_SCCM_DP $false

#SCCMF_Affichage "SCCM DP UDP" $Dests_SCCM_DP_UDP $ports_SCCM_DP_UDP $true



Log_f
$V_fin = Get-Date
$v_trait = $v_fin - $v_debut

Log_f ""
Log_f "-------------------------------------------------------------" "Magenta"
Log_f "       End of : $v_Title                                     " "Magenta"
Log_f "  Processing time : $v_trait                                 " "Magenta"
Log_f "  Have a good day  ...                                       " "Magenta"
Log_f "-------------------------------------------------------------" "Magenta"
Log_f ""

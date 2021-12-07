#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <csgocolors>
#include <warden>
#include <smlib>

new bool:CanUseCommand = true;
new g_CollisionOffset;

public Plugin:myinfo =
{
    name = "Noblock",
    author = "Krotis aka Rank95",
    description = "none",
    version = "1.0",
    url = "http://gameonline.nu"
}

public OnPluginStart()  
{ 
	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");   
    RegConsoleCmd("sm_noblockon", on); 
    RegConsoleCmd("sm_noblockoff", off); 

}     



EnableNoBlock(client)
{
	SetEntData(client, g_CollisionOffset, 2, 4, true);
}


EnableBlock(client)
{
	SetEntData(client, g_CollisionOffset, 5, 4, true);
}


public Action:on(client, args) 
{ 
	if (warden_iswarden(client) == CanUseCommand)  
    {
	
	LOOP_CLIENTS(i, CLIENTFILTER_TEAMONE)
				{
						new userid = GetClientUserId(i);
						EnableNoBlock(i);	
				}

	CPrintToChatAll("{green}[NoBlock] {normal}{purple}Noblock {normal}is currently on."); 
	    }
    else  
    {
        CPrintToChat(client, "{green}[NoBlock] {normal}Only {purple}Warden {normal}can use !noblockon.");  
    }
} 

public Action:off(client, args) 
{ 
   	if (warden_iswarden(client) == CanUseCommand)  
    {
   LOOP_CLIENTS(i, CLIENTFILTER_TEAMONE)
				{
						new userid = GetClientUserId(i);
						EnableBlock(i);	
				}
	CPrintToChatAll("{green}[NoBlock] {normal}{purple}Noblock {normal}is currently off.");  
	    }
    else  
    {
        CPrintToChat(client, "{green}[NoBlock] {normal}Only {purple}Warden {normal}can use !noblockoff."); 
    }
}  

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontbroadcast)
{
    LOOP_CLIENTS(i, CLIENTFILTER_TEAMONE)
				{
						new userid = GetClientUserId(i);
						EnableBlock(i);	
				}
}  

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
public Plugin:myinfo = {
    
    name = "Defib Healing Plus",
    author = "Joshua Coffey + Grammernatzi",
    description = "Allows players to heal alive players with defibs to a set max health (50 by default), as well as quick revive incapacitated players with them.",
    version = "1.0.0.1",
    url = "http://www.sourcemod.net/"
    
}


new Handle:chat = INVALID_HANDLE;
new Handle:hint = INVALID_HANDLE;
new Handle:health = INVALID_HANDLE;
new Handle:maxHealth = INVALID_HANDLE;
new Handle:incap = INVALID_HANDLE;
new Handle:eraseTempHealthCvar = INVALID_HANDLE;

int hintsDisplayed[MAXPLAYERS+1];

public void OnClientPutInServer(int client)
{
	hintsDisplayed[client] = 0;
}

public OnPluginStart() {
    
    HookEvent("defibrillator_used_fail",defail);
    chat = CreateConVar("sm_defib_chat", "1", "Tell players when a user heals another user with a defib.")
    hint = CreateConVar("sm_defib_hint", "1", "Tell players that they can heal others with defibrillators when picking them up for the first time.")
    health = CreateConVar("sm_defib_health", "50", "The amount of health to give to player when using defibs on them.")
    maxHealth = CreateConVar("sm_defib_health_max", "50", "The max amount of health a player can be healed up to with a defib.")
    incap = CreateConVar("sm_defib_incap", "1", "Value for whether you can revive incapacitated players with a defibrillator. (1 = on, 0 = off)")
    eraseTempHealthCvar = CreateConVar("sm_defib_erase_temp_health", "1", "Whether to delete temp health after getting defib healed. (1 = on, 0 = off)")
	
    AutoExecConfig(true, "defibs");
}

public void OnConfigsExecuted()
{
	HookEvent("item_pickup", hintDisplay);
}

void CheatCommand(int client, const char[] command, const char[] arguments = "")
{
	int iCmdFlags = GetCommandFlags(command), iFlagBits = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetUserFlagBits(client, iFlagBits);
	SetCommandFlags(command, iCmdFlags|FCVAR_CHEAT);
}

public void hintDisplay(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	new hintDo = GetConVarInt(hint)

	char sTemp[20];
	event.GetString("item", sTemp, sizeof(sTemp));
	if( strcmp(sTemp, "defibrillator") == 0 && hintDo && hintsDisplayed[client] == 0)
	{
		if (GetConVarInt(incap)) PrintHintText(client, "Defibs can heal live teammates up to %i health, even while they're downed.", GetConVarInt(maxHealth))
		else PrintHintText(client, "Defibs can heal live teammates up to %i health.", GetConVarInt(maxHealth))
		hintsDisplayed[client]++;
	}
}

public defail(Handle:event, const String:name[], bool:dontBroadcast)
{
    new eraseTempHealth = GetConVarInt(eraseTempHealthCvar)
    new healthdone = 0
    new subjectMaxHealth = GetConVarInt(maxHealth)
    new chatdo = GetConVarInt(chat)
    new incapDo = GetConVarInt(incap)
    new healthremainder = subjectMaxHealth - GetConVarInt(health)
    new user_id = GetEventInt(event, "userid")
    new healthtoadd = GetConVarInt(health)
    new subject_id = GetEventInt(event, "subject")
    new subject = GetClientOfUserId(subject_id)
    new user = GetClientOfUserId(user_id)
    new subjecthealth = GetClientHealth(subject)
    new subjectIncapacitated = GetEntProp(subject, Prop_Send, "m_isIncapacitated", 1)
    new defibrillator = GetPlayerWeaponSlot(user, 3);
    
    if(subjecthealth < subjectMaxHealth || (incapDo && subjectIncapacitated))
	{
        
        CheatCommand(subject, "give", "health")
		
        if (incapDo && subjectIncapacitated)
        {
             SetEntityHealth(subject,healthtoadd)
        }
        else if(subjecthealth > healthremainder){
            
            for(new i = subjecthealth; i < subjectMaxHealth; i++){
                
                healthdone++
                
            }
            
            SetEntityHealth(subject,subjectMaxHealth)
            
        }
        else{
            
            SetEntityHealth(subject, subjecthealth + healthtoadd)
            
        }
		
        if (eraseTempHealth) SetEntPropFloat(subject, Prop_Send, "m_healthBuffer", 0.0);
        
        if(chatdo){
            
            if (subjectIncapacitated && incapDo)
            {
                PrintToChatAll("%N revived %N from incapacitation with a defib.", user, subject)
            }
            else{
                PrintToChatAll("%N brought up %N to %i health via defib.", user, subject, GetClientHealth(subject))
                
            }
            
            
        }
        
        RemovePlayerItem(user, defibrillator);
        
    }
    
    
}
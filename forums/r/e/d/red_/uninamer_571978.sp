#pragma semicolon 1

#include <sourcemod>



/* CHANGELOG
*
* 1.2 added un_mingoodcharsequence
* 1.1 added a kick-option instead of renaming
* 1.0.2 implemented full utf-8 support
* 1.0.1 minor changes on debug output; fixed bug on round-end check
* 1.0 added cvars un_characterthreshold and un_maxbadchars; added round end checks; added check for name termination char
* 0.1: Initial
*
*/

/********************************************************************
 *
 * Definitions
 *
 ********************************************************************/
 
#define PLUGIN_VERSION "1.2"
#define TRANSLATION_FILE "uninamer.phrases"


/********************************************************************
 *
 * Static declarations
 *
 ********************************************************************/
 
new Handle:s_enable;
new Handle:s_punishmode;
new Handle:s_defaultName;
new Handle:s_characterThresholdVar;
new s_characterThreshold;
new Handle:s_maxBadCharsVar;
new Handle:s_minGoodCharSequenceVar;
new s_maxBadChars;
new s_minGoodCharSequence;

/********************************************************************
 *
 * Global Callbacks
 *
 ********************************************************************/
 
public Plugin:myinfo = 
{
	name = "Uninamer",
	author = "red!",
	description = "renames unicode abuser to default name",
	version = PLUGIN_VERSION,
	url = "http://www.hanse-clan.de"
};


/*
 * Plugin Start Callback triggered by sourcemod on plugin initialization
 * 
 * parameters: -
 * return: -
 */
 
public OnPluginStart()
{

	CreateConVar("uninamer_version", PLUGIN_VERSION, "Version of Uninamer", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	LoadTranslations(TRANSLATION_FILE);
	
	// register console cvars
		
	s_enable = CreateConVar("un_enable", "1", "disable/enable uninamer");
	s_punishmode = CreateConVar("un_punishmode", "0", "0: rename player, 1: kick player");
	s_defaultName = CreateConVar("un_defaultname", "bad name", "name to use for unicode abusers");
	s_characterThresholdVar = CreateConVar("un_characterthreshold", "160", "last character which will be allowed");
	s_maxBadCharsVar = CreateConVar("un_maxbadchars", "2", "number of unicode character that are allowed for a single name");
	s_minGoodCharSequenceVar = CreateConVar("un_mingoodcharsequence", "0", "number of allowed characters that need to be in a continous sequence");

	HookEvent("round_end",OnRoundEnd,EventHookMode_Pre);
}



/*
 * Callback triggered by sourcemod on client connection
 * 
 * parameters: client: client slot id (0 to maxplayers-1)
 * return: -
 */
 
public OnClientPostAdminCheck(clientSlot)
{
	// plugin deactivated
	if (GetConVarInt(s_enable)==0) return;

	s_characterThreshold = GetConVarInt(s_characterThresholdVar);
	s_maxBadChars = GetConVarInt(s_maxBadCharsVar);
	s_minGoodCharSequence = GetConVarInt(s_minGoodCharSequenceVar);
	nameCheck(clientSlot);
	
}

public OnRoundEnd(Handle: event , const String: name[] , bool: dontBroadcast)
{
	if (GetConVarInt(s_enable)==0) return;
	
	s_characterThreshold = GetConVarInt(s_characterThresholdVar);
	s_maxBadChars = GetConVarInt(s_maxBadCharsVar);
	s_minGoodCharSequence = GetConVarInt(s_minGoodCharSequenceVar);
	for (new i=1; i<=GetMaxClients(); i++) 
	{
		if (IsClientInGame(i))
		{
			nameCheck(i);
		}	
	}
	return;
}


/********************************************************************
 *
 * Custom Functions
 *
 ********************************************************************/

nameCheck(clientSlot)
{
	new String:nameBuf[128+4];
	if (GetClientName(clientSlot, nameBuf, 128))
	{
		new uni=0;
		new nameLenght=0;
		new longestGoodCharSequence=0;
		new currentGoodCharSequence=0;
		new currentChar; 
		for (new i=0;i<128 && nameBuf[i]!=0;i++)
		{
			// estimate current charater value
			if ((nameBuf[i]&0x80) == 0) // single byte charater?
			{
				currentChar=nameBuf[i];
			} else if (((nameBuf[i]&0xE0) == 0xC0) && ((nameBuf[i+1]&0xC0) == 0x80)) // two byte charater?
			{
				currentChar=(nameBuf[i++] & 0x1f); currentChar=currentChar<<6;
				currentChar+=(nameBuf[i] & 0x3f); 
			} else if (((nameBuf[i]&0xF0) == 0xE0) && ((nameBuf[i+1]&0xC0) == 0x80) && ((nameBuf[i+2]&0xC0) == 0x80)) // three byte charater?
			{
				currentChar=(nameBuf[i++] & 0x0f); currentChar=currentChar<<6;
				currentChar+=(nameBuf[i++] & 0x3f); currentChar=currentChar<<6;
				currentChar+=(nameBuf[i] & 0x3f);
			} else if (((nameBuf[i]&0xF8) == 0xF0) && ((nameBuf[i+1]&0xC0) == 0x80) && ((nameBuf[i+2]&0xC0) == 0x80) && ((nameBuf[i+3]&0xC0) == 0x80)) // four byte charater?
			{
				currentChar=(nameBuf[i++] & 0x07); currentChar=currentChar<<6;
				currentChar+=(nameBuf[i++] & 0x3f); currentChar=currentChar<<6;
				currentChar+=(nameBuf[i++] & 0x3f); currentChar=currentChar<<6;
				currentChar+=(nameBuf[i] & 0x3f);
			} else 
			{
				currentChar=s_characterThreshold+1; // reaching this may be caused by bug in sourcemod or some kind of bug using by the user - for unicode users I do assume last ...
				PrintToServer("[Uninamer] invalid UTF-8 encoding: %s", nameBuf[i]);
				LogMessage("invalid UTF-8 encoding: %s", nameBuf[i]);
			}
			
			// decide if character is allowed
			if (currentChar>s_characterThreshold)
			{
				uni++;
				if (currentGoodCharSequence>longestGoodCharSequence)
				{
					longestGoodCharSequence=currentGoodCharSequence;
				}
				currentGoodCharSequence=0;
			} else
			{
				currentGoodCharSequence++;
			}
		}
		if (currentGoodCharSequence>longestGoodCharSequence)
		{
			longestGoodCharSequence=currentGoodCharSequence;
		}
		// decide about the total amount of bad chars
		if (uni>s_maxBadChars)
		{	
			new punishMode = GetConVarInt(s_punishmode);
			if (punishMode==0) // rename
			{
				PrintToServer("[Uninamer] renaming %s (bad chars: %d>%d)", nameBuf, uni, s_maxBadChars);
				LogMessage("renaming %s (bad chars: %d>%d)", nameBuf, uni, s_maxBadChars);
				GetConVarString(s_defaultName, nameBuf, 128);
				ClientCommand(clientSlot, "name \"%s\"", nameBuf);
			} else { // kick
				PrintToServer("[Uninamer] kicking %s (bad chars: %d>%d)", nameBuf, uni, s_maxBadChars);
				LogMessage("kicking %s (bad chars: %d>%d)", nameBuf, uni, s_maxBadChars);
				CreateTimer(0.1, OnTimedKick, GetClientUserId(clientSlot));
			}
		}
		// decide about the minimal sequence of good chars
		if (longestGoodCharSequence<s_minGoodCharSequence)
		{	
			new punishMode = GetConVarInt(s_punishmode);
			if (punishMode==0) // rename
			{
				PrintToServer("[Uninamer] renaming %s (minimum good char sequence: %d<%d)", nameBuf, longestGoodCharSequence, s_minGoodCharSequence);
				LogMessage("renaming %s (minimum good char sequence: %d<%d)", nameBuf, longestGoodCharSequence, s_minGoodCharSequence);
				GetConVarString(s_defaultName, nameBuf, 128);
				ClientCommand(clientSlot, "name \"%s\"", nameBuf);
			} else { // kick
				PrintToServer("[Uninamer] kicking %s (minimum good char sequence: %d<%d)", nameBuf, longestGoodCharSequence, s_minGoodCharSequence);
				LogMessage("kicking %s (minimum good char sequence: %d<%d)", nameBuf, longestGoodCharSequence, s_minGoodCharSequence);
				CreateTimer(0.1, OnTimedKick, GetClientUserId(clientSlot));
			}
		}
	}
	
}

public Action:OnTimedKick(Handle:timer, any:value)
{
	new clientSlot = GetClientOfUserId(value);
	
	if (!clientSlot || !IsClientInGame(clientSlot))
	{
		return Plugin_Handled;
	}

	KickClient(clientSlot, "%T", "unicode names not allowed here", clientSlot);
	return Plugin_Handled;
}



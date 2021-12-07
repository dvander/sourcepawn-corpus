#define PLUGIN_VERSION		"0.1"

#define BUFFER_SIZE			8192
#define CONVAR_SIZE			256 // ConVars length are max 255 bytes, cannot return longer values from VScripts with this method.

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar gCvarBuffer;



// ====================================================================================================
//					PLUGIN INFO
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] Execute VScript Get Return",
	author = "SilverShot",
	description = "Returns the value from a VScript code for use within SourcePawn.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=317128"
}



// ====================================================================================================
//					PLUGIN START / END
// ====================================================================================================
public void OnPluginStart()
{
	CreateConVar("sm_vscript_return_version", PLUGIN_VERSION, "VScript Return version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gCvarBuffer = CreateConVar("sm_vscript_return", "", "Buffer used to return vscript values. Do not use.");

	RegAdminCmd("sm_scripter",			CmdScriptReturn,	ADMFLAG_ROOT,	"Usage: sm_scripter <code>. Prints the return value.");
	RegAdminCmd("sm_scripter_test",		CmdScriptTest,		ADMFLAG_ROOT,	"Trigger to test various stocks.");
}

public Action CmdScriptReturn(int client, int args)
{
	char buffer[BUFFER_SIZE];
	GetCmdArg(1, buffer, sizeof buffer);

	if( GetVScriptOutput(buffer, buffer, sizeof buffer) )
	{
		ReplyToCommand(client, "[SM] Return: %s", buffer);
	} else {
		ReplyToCommand(client, "[SM] Error: Script return failed.");
	}

	return Plugin_Handled;
}

public Action CmdScriptTest(int client, int args)
{
	char buffer[CONVAR_SIZE];
	int target;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsPlayerAlive(i) )
		{
			target = i;
			break;
		}
	}

	if( target )
	{
		float distance, vPos[3];

		GetClientAbsOrigin(target, vPos);
		ReplyToCommand(client, "Vscript Return Buffer Target: %N", target);
		ReplyToCommand(client, "");

		distance = VecFlowDistance(vPos);
		ReplyToCommand(client, "VecFlowDistance() == %f", distance);
		ReplyToCommand(client, "");

		distance = GetFlowDistance(target);
		ReplyToCommand(client, "GetFlowDistance() == %f", distance);
		ReplyToCommand(client, "");
	}

	ReplyToCommand(client, "GetMaxDistance() == %f", GetMaxDistance());
	ReplyToCommand(client, "");

	GetGameMode(buffer, sizeof buffer);
	ReplyToCommand(client, "GetGameMode() == [%s]", buffer);
	ReplyToCommand(client, "");

	GetRandomPlayerName(buffer, sizeof buffer);
	ReplyToCommand(client, "GetRandomPlayerName() == [%s]", buffer);
	ReplyToCommand(client, "");

	int test = MathAdd(3, 14);
	ReplyToCommand(client, "MathAdd() == [%d]", test);
	ReplyToCommand(client, "");

	TestStr(buffer, sizeof buffer);
	ReplyToCommand(client, "TestStr() == [%s]", buffer);
	ReplyToCommand(client, "");

	return Plugin_Handled;
}



// ====================================================================================================
//					RANDOM STOCKS
// ====================================================================================================
stock float VecFlowDistance(float vPos[3])
{
	// Execute a single code block
	char buffer[256];
	Format(buffer, sizeof buffer, "GetFlowDistanceForPosition(Vector(%f, %f, %f))", vPos[0], vPos[1], vPos[2]);
	GetVScriptOutput(buffer, buffer, sizeof buffer);
	return StringToFloat(buffer);
}

stock float GetFlowDistance(int client)
{
	char buffer[256];
	Format(buffer, sizeof buffer, "GetCurrentFlowPercentForPlayer(%d)", client);
	GetVScriptOutput(buffer, buffer, sizeof buffer);
	return StringToFloat(buffer);
}

stock float GetMaxDistance()
{
	char buffer[256];
	GetVScriptOutput("GetMaxFlowDistance()", buffer, sizeof buffer);
	return StringToFloat(buffer);
}

stock void GetGameMode(char[] buffer, int maxlength)
{
	GetVScriptOutput("Director.GetGameMode()", buffer, maxlength);
}

stock void GetRandomPlayerName(char[] buffer, int maxlength)
{
	// Execute several code blocks, must wrap the section you want to return within <RETURN> </RETURN> otherwise the script will fail.
	GetVScriptOutput("local player = null; while(player = Entities.FindByClassname(player, \"player\")) { if(player.IsSurvivor()) { <RETURN>player.GetName()</RETURN> } }", buffer, maxlength);
}

stock int MathAdd(int a, int b)
{
	char buffer[256];
	Format(buffer, sizeof buffer, "test_a <- %d; test_b <- %d; <RETURN>test_a + test_b</RETURN>", a, b);
	GetVScriptOutput(buffer, buffer, sizeof buffer);
	return StringToInt(buffer);
}

stock int TestStr(char[] buffer, int maxlength)
{
	Format(buffer, maxlength, "<RETURN>314</RETURN>");
	GetVScriptOutput(buffer, buffer, maxlength);
	return StringToInt(buffer);
}



// ====================================================================================================
//					FUNCTION
// ====================================================================================================
/**
* Runs a single line of VScript code and returns values from it.
*
* @param	code			The code to run.
* @param	buffer			Buffer to copy to.
* @param	maxlength		Maximum size of the buffer.
* @return	True on success, false otherwise.
* @error	Invalid code.
*/
stock bool GetVScriptOutput(char[] code, char[] buffer, int maxlength)
{
	static int logic = INVALID_ENT_REFERENCE;
	if( logic == INVALID_ENT_REFERENCE || !IsValidEntity(logic) )
	{
		logic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if( logic == INVALID_ENT_REFERENCE || !IsValidEntity(logic) )
			SetFailState("Could not create 'logic_script'");

		DispatchSpawn(logic);
	}

	// Return values between <RETURN> </RETURN>
	int pos = StrContains(code, "<RETURN>");
	if( pos != -1 )
	{
		strcopy(buffer, maxlength, code);
		// If wrapping in quotes is required, use these two lines instead.
		// ReplaceString(buffer, maxlength, "</RETURN>", " + \"\");");
		// ReplaceString(buffer, maxlength, "<RETURN>", "Convars.SetValue(\"sm_vscript_return\", \"\" + ");
		ReplaceString(buffer, maxlength, "</RETURN>", ");");
		ReplaceString(buffer, maxlength, "<RETURN>", "Convars.SetValue(\"sm_vscript_return\", ");
	}
	else
	{
		Format(buffer, maxlength, "Convars.SetValue(\"sm_vscript_return\", \"\" + %s + \"\");", code);
	}

	// Run code
	SetVariantString(buffer);
	AcceptEntityInput(logic, "RunScriptCode");
	AcceptEntityInput(logic, "Kill");

	// Retrieve value and return to buffer
	gCvarBuffer.GetString(buffer, maxlength);
	gCvarBuffer.SetString("");

	if( buffer[0] == '\x0')
		return false;
	return true;
}
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1


AddCommandListener(Command_Join, "jointeam");

public Action:Command_Join(client, const String:command[], argc)
{
    if(client && IsClientInGame(client))
    {
        decl String:_sTemp[3];
        GetCmdArg(1, _sTemp, sizeof(_sTemp));
        new _iTemp = StringToInt(_sTemp);

		if(_iTemp >= 2)
		{
		  //Client is attempting to join terrorist or counter-terrorist
		}  
    }
}  
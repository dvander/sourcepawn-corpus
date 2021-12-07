#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegAdminCmd("sm_disablecp", Command_Disable, ADMFLAG_GENERIC);
	RegAdminCmd("sm_enablecp", Command_Enable, ADMFLAG_GENERIC);
}

public Action:Command_Enable(client, args)
{
	DisableControlPoints(false);
	return Plugin_Handled;
}
public Action:Command_Disable(client, args)
{
	DisableControlPoints(true);
	return Plugin_Handled;
}
public DisableControlPoints(bool:capState)
{
    new i = -1;
    new CP = 0;

    for (new n = 0; n <= 16; n++)
    {
        CP = FindEntityByClassname(i, "trigger_capture_area");
        if (IsValidEntity(CP))
        {
            if(capState)
            {
                AcceptEntityInput(CP, "Disable");
            }else{
                AcceptEntityInput(CP, "Enable");
            }
            i = CP;
        }
        else
            break;
    }
}  

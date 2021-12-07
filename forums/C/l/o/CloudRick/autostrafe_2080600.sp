#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
 
 
new bool:RIGHT[MAXPLAYERS+1] = {false,...};
new bool:LEFT[MAXPLAYERS+1] = {false,...};
new bool:Misc_Autostrafe[MAXPLAYERS+1] = {false,...};
new Float:Second[MAXPLAYERS+1][3];
new Float:AngDiff[MAXPLAYERS+1];
 
 
 public Plugin:myinfo = 
{
    name = "Autostrafe",
    author = "Swillzyy^",
    description = "Autostrafe function perfect for bhop servers.",
    version = "1.0",
    url = "http://spelkretsen.se/"
}
public OnPluginStart()
{
        RegConsoleCmd("sm_strafe", Cmd_Autostrafe, "Command to activate autostrafe on ourselves");
        RegConsoleCmd("sm_autostrafe", Cmd_Autostrafe, "Command to activate autostrafe on ourselves");
 
}
 
public Action:OnTimerStart(client, Type, Style)
{
        if(Misc_Autostrafe[client] = true)
        {
                return Plugin_Handled;
        }
        return Plugin_Continue;
}
 
 
public Action:Cmd_Autostrafe(client, args)
{
        if (Misc_Autostrafe[client] == true)
        {
                Misc_Autostrafe[client] = false;
                PrintToChat(client, "\x04[Misc] \x07FFFFFFAutostrafe - Off.");
        }
        else if (Misc_Autostrafe[client] == false)
        {
                Misc_Autostrafe[client] = true;
                PrintToChat(client, "\x04[Misc] \x07FFFFFFAutostrafe - On.");
        }
        return Plugin_Handled;
}
 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
        if(IsClientInGame(client))
        {
                if(Misc_Autostrafe[client] == true && IsPlayerAlive(client) && !(GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(buttons & IN_FORWARD) && !(buttons & IN_BACK) && !(buttons & IN_MOVELEFT) && !(buttons & IN_MOVERIGHT))
                {
                        AngDiff[client] = Second[client][1]-angles[1];
                        Second[client] = angles;
                        if (AngDiff[client] > 180)
                                AngDiff[client] -= 360;
                        if (AngDiff[client] < -180)
                                AngDiff[client] += 360;
                       
                        if(AngDiff[client] < 0 || LEFT[client])
                        {
                                vel[1] = -400.0;
                                LEFT[client] = true;
                                RIGHT[client] = false;
                        }      
                        if(AngDiff[client] > 0 || RIGHT[client])
                        {
                                vel[1] = 400.0;
                                RIGHT[client] = true;
                                LEFT[client] = false;
                        }
                }
                else
                {
                        RIGHT[client] = false;
                        LEFT[client] = false;
                }
        }
        return Plugin_Continue;
}
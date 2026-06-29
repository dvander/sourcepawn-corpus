/* Random melon sounds for maximum server quality */
#include <sdktools_sound.inc>

public void OnPluginStart()
{
    AddCommandListener(MelonSound, "say");
    AddCommandListener(MelonSound, "say_team");
}

public Action:MelonSound(int client, const char[] command, int argc)
{
    decl String:cmd[255];
    GetCmdArgString(cmd, 255);
    ReplaceString(cmd, 255, "\"", ""); // remove quotes

    if (StrEqual(cmd, "melon", false)) // if they type melon in chat
    {
        // save random melon sound with random pitch
        decl String:melonSnd[60];
        Format(melonSnd, 60, "physics/flesh/flesh_squishy_impact_hard%i.wav", GetRandomInt(2, 4));
        
        // play random melon sound
        PrecacheSound(melonSnd);
        EmitSoundToAll(melonSnd, _, _, _, _, _, GetRandomInt(50, 200), _, _, _, _, _); 

        // save client's name
        decl String:clientName[35];
        GetClientName(client, clientName, 35);

        // put random melon message
        decl String:randMelonMsg[][] = {
            {"slapped"}, 
            {"threw"},
            {"chopped"},
            {"hugged"},
            {"kicked"},
            {"dropped"},
            {"shot"},
            {"pet"},
            {"punched"},
            {"ate"},
            {"licked"},
            {"smashed"},
            {"squeezed"}
        }

        decl String:randTxt[255];
        Format(randTxt, 255, "%s %s a melon.", clientName, randMelonMsg[GetRandomInt(0, sizeof(randMelonMsg) - 1)]);
        PrintToChatAll(randTxt);
        
        return Plugin_Stop; // hide Name : melon
    }

    return Plugin_Continue;
}
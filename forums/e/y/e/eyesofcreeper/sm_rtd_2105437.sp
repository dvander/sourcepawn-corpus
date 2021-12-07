#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <morecolors>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.23"

new Lastone;
new Broken;
public Plugin:myinfo =
{
    name = "Poon rtd",
    author = "Eyesofcreeper steam:newmine",
    description = "Fake rtd :)",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
    //RegConsoleCmd("sm_rtd", Roll_The_Dice, "Lunch the dice and get a message.");
    //RegConsoleCmd("rtd", Roll_The_Dice, "Lunch the dice and get a message."); same of the first RegConsoleCmd
    RegConsoleCmd("sm_repair", Repair_The_Dice, "Repair the dice.");
    CreateConVar("sm_poonrtd_version", PLUGIN_VERSION, "Version of Poon RTD", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    AddCommandListener(Listener_Say, "say");
    AddCommandListener(Listener_Say, "say_team");
}

    

RTD(client)
{
    if(client == 0) return 0;

    if(Broken == 1)
    {
        CPrintToChatAllEx(client,"{green}[RTD] {default}The dices are broken. Use !repair to repair them, {teamcolor}%N{default}.", client);
        return 0;
    }
    if (Lastone == client)
    {
        CPrintToChatAllEx(client,"{green}[RTD] {default}Stop hogging the dice, {teamcolor}%N{default}.", client);
        return 0;
    }

    Lastone = client;
    switch (GetRandomInt(1, 48))
    {
        case 1:
    {
        CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}lauched the dice and... Oh no ! He has lunched the dice behind the fridge ! Anyway, what the fuck is there a fridge on this map ?", client);
        Broken = 1;
    }
        case 2:
    {
        CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}roll the dice and won hammer. DONT TEST IT ON THE DICE ! Too late.", client);
        Broken = 1;
    }
        case 3:
    {
        CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}tried to roll the dice but they don't want to be rolled. ", client);
        Broken = 1;
    }
        case 4:
    {
        CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}tried to roll the dice but they have been eaten by a bird. ", client);
        Broken = 1;
    }
        case 5:
    {
        CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}eat the dice and feels funny.", client);
        Broken = 1;
    }
        case 6:
    {
        CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled the dice in front of a pyro. The dices are now incinerated !.", client);
        Broken = 1;
    }
        case 7:
    {
        CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}pass the dice to Chuck Norris. Chuck Norris send them into SPAAAAAAAACE !", client);
        Broken = 1;
    }
        
        case 8: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}launched the dice and rolled a 2. Good one.", client);
        case 9: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}lauched the dice and got invisibility. This perk only work when nobody looks to it.", client);
        case 10: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled super strenght. Squeeze that last bit out of your toothpaste.", client);
        case 11: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}just donated 20$ to the server. Thanks", client);
        case 12: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}just won a reserved slot on the himself server. Avariable when the server is not full.", client);
        case 13: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled waffles. 4/3 cup flour, 4 tsp baking powder, 1/2 tsp salt,2 tsp sugar, 2 eggs, 1/2 cup butter, 7/4 cup milk. Go.", client);        
        case 14: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}launched the dice and won a free kill. Could someone in the other team stop moving so the prize could be claimed ?", client);
        case 15: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}launched the dice and rolled noclip. But, because noclip comes from the same factory that created the dice, noclip is broken.", client);
        case 16: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}launched the dice and rolled a 3. Half life 3 confirmed !", client);
        case 17: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}must go directly to the jail. Do not pass GO. Do not collect 200$.", client);
        case 18: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}lunched the dice and got GlaDos. You're invited to the Aperture Science Corporation... In 1200 years. She'll be still alive.", client);
        case 19: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled the dice. You're so strong !", client);
        case 20: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled double jump. Work only as scout !", client);
        case 21: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled insta-respawn, after you have died and wait for at least 20 seconds!", client);
        case 22: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}has been granted 100% accuracy when aiming at a wall !", client);
        case 23: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}captured the intelligence, amazing since this is a idle map !", client);
        case 24: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}have won a crate! Please continue playing to receive your prize. !", client);
        case 25: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}and win the right to re-lunch the dice... Later !", client);
        case 26: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled the dice and has unlocked the use of Mouse2 !", client);
        case 27: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled the dice and has unlocked the ability to count to 3 !", client);
        case 28: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled the dice and unlocked the ability to jump !", client);
        case 29: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled the dice and increased their chance of a hat dropping in the next 2 minutes by 0.003 percent !", client);
        case 30: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}has rolled Invisibility! As a spy, right click to activate.", client);
        case 31: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}gained the ability to travel through time at a rate of one second per second !", client);
        case 32: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N{default}'s !rtd is not responding , the thing has crashed and nothing is given !", client);
        case 33: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}now has reduced loading times! Decreased by 0.0001 nanoseconds.", client);
        case 34: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}has won unlimited health and ammo. Remain next to a supply locker to keep active !", client);
        case 35: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled Double Speed! Takes place when you are not moving !", client);
        case 36: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled Instant Ubercharge! Takes place when you are ubercharged !", client);
        case 37: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled free kill ! Please, type suicide in the console.", client);
        case 38: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled fire arrows ! Only works as spy.", client);
        case 39: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled backpack expander. Your backpack have been grown by -2 slots.", client);
        case 40: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}won critical hits. Works with Bonk! Atomic Punch and hats only.", client);
        case 41: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}won health. Your health have been multiplied by 10 then divided by 5x2 !", client);
        case 42: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}secret admirer. You have now a secret admirer on the other team, but who is he ?", client);
        case 43: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}won the scout's pistol. Oh shit, you already have it !", client);
        case 44: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled lighter. You can use it to deals 0.0001 damage on pyro.", client);
        case 45: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled internet! You can now connect to the internet.", client);
        case 46: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}won chair. You can now sit down to play tf2, witch is a better idea anyway !", client);
        case 47: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}rolled off button. Press this button on your computer to win !", client);
        case 48: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}won the right to loose nothing !", client);
        case 49: CPrintToChatAllEx(client,"{green}[RTD] {teamcolor} %N {default}got a 7. You have been reported to VAC for dice cheating !", client);

    }
    return 1;
}    

//public Action:Roll_The_Dice(client, args)
//{
//    RTD(client);
//    return Plugin_Handled;
//}


public Action:Repair_The_Dice(client, args)
{
    if (Broken == 1)
    {
        Broken = 0;
        CPrintToChatAllEx(client,"{green}[RTD]{teamcolor} %N {default} found a new dice !", client);
        return Plugin_Handled;
    }
    else 
    {
        Broken = 0;
        CPrintToChatAllEx(client,"{green}[RTD]{teamcolor} %N {default} try to repair a good dice.", client);
        return Plugin_Handled;
    }  
}  

public Action:Listener_Say(client, const String:command[], argc)
{
    if(!client || client > MaxClients || !IsClientInGame(client)) return Plugin_Continue;
    
    decl String:strChat[100];
    GetCmdArgString(strChat, sizeof(strChat));
    new iStart;
    if(strChat[iStart] == '"') iStart++;
    if(strChat[iStart] == '!') iStart++;
    new iLength = strlen(strChat[iStart]);
    if(strChat[iLength+iStart-1] == '"')
    {
        strChat[iLength--+iStart-1] = '\0';
    }   
    

    if(StrContains(strChat[iStart], "rtd", false) != -1 && iLength <= 3)
    {
        RTD(client);
    }
    
    return Plugin_Continue;
}
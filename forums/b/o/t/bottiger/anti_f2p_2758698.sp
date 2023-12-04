#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <SteamWorks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
    name        = "Free2BeKicked Skial",
    author      = "Bottiger, Asher \"asherkin\" Baker",
    description = "Automatically kicks non-premium players.",
    version     = PLUGIN_VERSION,
    url         = "http://limetech.org/"
};

ConVar anti_f2p_enabled;
ConVar anti_f2p_fullkick;
ConVar sv_visiblemaxplayers;

public void OnPluginStart()
{
    anti_f2p_enabled = CreateConVar("anti_f2p_enabled", "1", "Enable kicking of F2P");
    anti_f2p_fullkick = CreateConVar("anti_f2p_fullkick", "1", "Only kick F2P when server is full");
    sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");  
}

public void OnClientPostAdminCheck(client)
{
    if (GetConVarBool(anti_f2p_enabled))
    {
        int maxplayers = GetConVarInt(sv_visiblemaxplayers);
        if (maxplayers == -1) 
        {
            maxplayers = MaxClients;
        }

        // kick if f2p
        if (!GetConVarBool(anti_f2p_fullkick) && IsFreeToPlay(client))
        {
            KickClient(client, "This is a trade server and you cannot trade with a F2P account. Donate or get a Premium TF2 account");
            return;
        }

        // try to kick a f2p is the server is full
        if (GetClientCount(false) >= maxplayers)
        {
            KickF2P();
        }        
    }
}

bool IsFreeToPlay(int client)
{
    bool notadmin = GetUserFlagBits(client) == 0;
    bool premium = SteamWorks_HasLicenseForApp(client, 459) == k_EUserHasLicenseResultHasLicense;
    return !notadmin && !premium;
}

void KickF2P()
{
    int freeCount = 0;
    int[] freeClients = new int[MaxClients];
    for(int i=1;i<=MaxClients;i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i) && IsFreeToPlay(i))
        {
            freeClients[freeCount] = i;
            freeCount++;
        }
    }

    if(freeCount == 0)
    {
        return;
    }

    SortCustom1D(freeClients, freeCount, SortFree);
    KickClient(freeClients[0], "This is a trade server and you cannot trade with a F2P account. Donate or get a Premium TF2 account");
}

int SortFree(int a, int b, int[] array, Handle h)
{
    float at = GetClientTime(a);
    float bt = GetClientTime(b);

    return -RoundToNearest(at-bt);
}
new PlVers:__version = 5;
new Float:NULL_VECTOR[3];
new String:NULL_STRING[1];
new Extension:__ext_core = 64;
new MaxClients;
new Extension:__ext_sdktools = 1396;
new Extension:__ext_sdkhooks = 1440;
new Extension:__ext_cstrike = 1484;
new Extension:__ext_vphysics = 1532;
new bool:EventGuerre;
new bool:InscriptionOn;
new NumeroClient[21];
new JoueurVivant[21];
new Float:zoneTpEventG[21][3];
new Handle:db;
new bool:PluginLoaded;
new annee;
new jour;
new nbmois;
new minute;
new String:mois[4];
new String:heureminu[2];
new heure;
new seconde;
new Handle:insertNewUser;
new Handle:insertNewUser2;
new Handle:updateUser;
new Handle:updateUser2;
new Handle:updateUser3;
new Handle:updateUser4;
new Handle:updateUser5;
new offsPunchAngle;
new grabbedentref[65];
new keybuffer[65];
new Float:grabangle[65][3];
new Float:grabdistance[65];
new Float:playeranglerotate[65][3];
new Float:nextactivetime[65];
new smokesprite;
new g_bloodModel;
new g_sprayModel;
new listPropPrix[12];
new String:listPropNom[12][15];
new m_vecOrigin;
new String:EndroitDuBillet[7][18];
new Float:PositionDuBillet[7][3];
new bool:grenadeNapalm[65];
new String:RaisonJail[16][10];
new tempsDeJail[16];
new prixDeJail[16];
new objetPrix[84];
new objetEffet[84];
new String:objetNom[84][8];
new String:objetFonction[84][4];
new objetIdAssoc[84];
new metierFric[41];
new String:metierNom[41][8];
new metierChef[41];
new metierIdAssoc[41];
new g_ExplosionSprite = -1;
new String:clientPseudo[65][8];
new clientTeam[65];
new String:clientSkin[65][8];
new clientIdMetier[65];
new clientCash[65];
new clientBank[65];
new clientLevelKnife[65];
new bool:clientPermiPri[65];
new bool:clientPermiSec[65];
new bool:clientInJail[65];
new clientTimeInJail[65];
new clientFermeture[65];
new bool:clientCutNapalm[65];
new clientPrecision[65];
new clientKill[65];
new clientDead[65];
new clientTotalKill[65];
new String:clientMaTuer[65][8];
new String:clientJaiTuer[65][8];
new clientTempsPasse[65];
new clientNbr1[65];
new clientItem1[65];
new clientNbr2[65];
new clientItem2[65];
new clientNbr3[65];
new clientItem3[65];
new clientNbr4[65];
new clientItem4[65];
new clientNbr5[65];
new clientItem5[65];
new clientNbr6[65];
new clientItem6[65];
new clientNbr7[65];
new clientItem7[65];
new clientNbr8[65];
new clientItem8[65];
new clientNbr9[65];
new clientItem9[65];
new clientNbr10[65];
new clientItem10[65];
new bool:clientDepoBank[65];
new String:clientObjetBank[65][23];
new bool:clientCarteCredit[65];
new bool:clientRibe[65];
new bool:clientVaccinPoison[65];
new bool:clientEmpoissone[65];
new bool:buttondelay[65];
new String:ListeAdminRoleplay[65][8];
new String:PluginVersion[15] = "1.0";
new g_iAccount = -1;
new String:arrayMois[12][3];
new listObjetArmes[28] =
{
    34, 35, 36, 37, 38, 39, 40, 41, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 79
}
new String:armePrimaire[6][8] =
{
    "weapon_usp",
    "weapon_glock",
    "weapon_p228",
    "weapon_deagle",
    "weapon_fiveseven",
    "weapon_elite"
}
new String:armeSecondaire[17][8] =
{
    "weapon_famas",
    "weapon_m4a1",
    "weapon_scout",
    "weapon_aug",
    "weapon_g3sg1",
    "weapon_awp",
    "weapon_m3",
    "weapon_xm1014",
    "weapon_tmp",
    "weapon_mp5navy",
    "weapon_ump45",
    "weapon_p90",
    "weapon_m249",
    "weapon_galil",
    "weapon_ak47",
    "weapon_sg552",
    "weapon_mac10"
}
new String:armeProjectile[3][8] =
{
    "weapon_flashbang",
    "weapon_smokegrenade",
    "weapon_hegrenade"
}
new String:armeC4[1][8] =
{
    "weapon_c4"
}
new String:nomZones[75][8];
new Float:listZones[75][2][3];
new typeDeZone[75];
new indexPorteZone[75];
new Float:zoneDeTelePort[75][3];
new listBoisson[9] =
{
    25, 26, 27, 28, 29, 30, 31, 32, 33
}
new listMetierSecu[4] =
{
    2, 3, 4, 5
}
new listMetiersSpe[5] =
{
    1, 2, 3, 4, 5
}
new listMetierChef[17] =
{
    6, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39
}
new listMetierSimple[18] =
{
    7, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40
}
new listMetierMafieu[6] =
{
    35, 36, 37, 38, 39, 40
}
new listIntChangSkins[5] =
{
    2, 3, 4, 5, 34
}
new listPorteForcer[12] =
{
    235, 248, 247, 244, 243, 696, 697, 694, 695, 537, 536, 530
}
new Handle:selectDoor;
new porteNumero[137];
new String:porteNom[137][8];
new porteProba[137];
new portePrix[137];
new porteLocation[137];
new porteIdAssocie[137];
new String:porteProprio1[137][8];
new String:porteProprio2[137][8];
new String:porteProprio3[137][8];
new String:porteProprio4[137][8];
new String:porteProprio5[137][8];
new String:pseudoProprio1[137][8];
new String:pseudoProprio2[137][8];
new String:pseudoProprio3[137][8];
new String:pseudoProprio4[137][8];
new String:pseudoProprio5[137][8];
new listPorteHotelPrinc[2] =
{
    105, 106
}
new listPorteVerifHotel[10] =
{
    108, 110, 112, 114, 116, 118, 120, 122, 124, 126
}
new listPorteEntrerJaune[4] =
{
    85, 84, 87, 86
}
new listPorteVerifJaune[4] =
{
    88, 90, 93, 96
}
new listePorteVerifEpic[2] =
{
    5, 8
}
new listAMafiaF[2] =
{
    49, 50
}
new listAMafiaI[2] =
{
    82, 83
}
new listAMafiaR[7] =
{
    63, 64, 65, 66, 67, 68, 69
}
new listPorteComico[31] =
{
    25, 26, 27, 28, 29, 30, 31, 34, 35, 36, 60, 61, 62, 76, 77, 78, 79, 80, 81, 128, 129, 130, 131, 132, 7, 105, 106, 84, 85, 86, 87
}
new listPorteComiGard[12] =
{
    25, 26, 27, 28, 29, 30, 31, 128, 129, 130, 131, 132
}
new Handle:nouvProprio1;
new Handle:nouvProprio2;
new Handle:nouvProprio3;
new Handle:nouvProprio4;
new Handle:nouvProprio5;
new Handle:panelAdmin;
new Handle:panelAdminlevelk;
new Handle:panelAddonneArg;
new Handle:panelAdPorte;
new Handle:panelAdPortArme;
new Handle:demissionUser;
new Handle:deleteUser;
new Handle:demissionSimple;
new Handle:g_MenuDonnerMetier;
new Handle:panelhopital;
new Handle:g_RecrutementMetierSimple;
new Handle:g_RecrutementMetierDocteur;
new Handle:g_RecrutementMetierInfirmier;
new Handle:updateBoss;
new Handle:selectSalarie;
new clientPropC4[65];
new Handle:g_MenuPizza;
new Handle:g_MenuDrogue;
new Handle:g_MenuMoniteur;
new Handle:g_MenuMedic;
new Handle:g_MenuArme;
new Handle:g_MenuBoisson;
new Handle:g_MenuSkins;
new Handle:g_MenuBanquier;
new Handle:g_MenuSerrurier;
new Handle:g_MenuCoutelier;
new Handle:g_MenuExplosif;
new Handle:g_MenuDetective;
new Handle:g_MenuIkea;
new Handle:g_MenuMafiaFReZ;
new Handle:g_MenuMafiaIta;
new Handle:g_MenuMafiaRusse;
new Handle:g_MenuVendPizza;
new Handle:g_MenuVendDrogue;
new Handle:g_MenuVendMedic;
new Handle:g_MenuVendArme;
new Handle:g_MenuVendBoisson;
new Handle:g_MenuVendskins;
new Handle:g_MenuVendMoniteur;
new Handle:g_MenuVendBanque;
new Handle:g_MenuVendSerrurier;
new Handle:g_MenuVendCoutelier;
new Handle:g_MenuVendExplosif;
new Handle:g_MenuVendDetective;
new Handle:g_MenuVendIkea;
new Handle:g_MenuVendMafiaFrez;
new Handle:g_MenuVendMafiaItal;
new Handle:g_MenuVendMafiaRusse;
new Float:SpawnFinJail[3] =
{
    1143775433, 1152596691, -1010631680
}
new g_BeaconSprite;
new g_Lightning;
new listPortePizzeria[4] =
{
    56, 57, 58, 59
}
new listPorteBar[3] =
{
    10, 11, 134
}
new listPorteIkea[3] =
{
    12, 13, 135
}
new lsitPorteBank[3] =
{
    16, 15, 14
}
new listPorteMoniteurTir[3] =
{
    37, 38, 39
}
new listPorteGarage[2] =
{
    41, 40
}
new listPorteArmurie[5] =
{
    42, 43, 44, 45, 46
}
new listPorteSeven[3] =
{
    47, 48, 133
}
new listPorteHopital[8] =
{
    97, 98, 99, 100, 101, 102, 103, 104
}
new listPorteCarshop[6] =
{
    70, 71, 72, 73, 74, 75
}
new listMagasin[13] =
{
    56, 4, 10, 12, 16, 32, 33, 37, 41, 42, 47, 97, 70
}
new listAH2[4] =
{
    0, 1, 2, 3
}
new listEpicAppartP1[2] =
{
    5, 6
}
new listEpicAppartP2[2] =
{
    8, 9
}
new listAH1[4] =
{
    21, 22, 23, 24
}
new listARDH[2] =
{
    88, 89
}
new listApremier[3] =
{
    90, 91, 92
}
new listAdeux[3] =
{
    93, 94, 95
}
new listPorteHoteP1[2] =
{
    108, 109
}
new listPorteHoteP2[2] =
{
    110, 111
}
new listPorteHoteP3[2] =
{
    112, 113
}
new listPorteHoteP4[2] =
{
    114, 115
}
new listPorteHoteP5[2] =
{
    116, 117
}
new listPorteHoteP6[2] =
{
    118, 119
}
new listPorteHoteP7[2] =
{
    120, 121
}
new listPorteHoteP8[2] =
{
    122, 123
}
new listPorteHoteP9[2] =
{
    124, 125
}
new listPorteHoteP10[2] =
{
    126, 127
}
new listAppartPrincipal[18] =
{
    0, 5, 8, 21, 88, 90, 93, 96, 108, 110, 112, 114, 116, 118, 120, 122, 124, 126
}
new Handle:panelNpcPrincipale;
new Handle:panelLeRoleplay;
new Handle:panelCommande;
new Handle:panelCommande1;
new Handle:panelInfoMetier;
new Handle:panelMetierExistant;
new Handle:panelInfoMagasin;
new Handle:panelInfoAppart;
new Handle:sltSalarie;
new Handle:selectSalaire;
new Handle:selectRecette;
new Handle:selectRecetteSal;
new Handle:deleteUneEntrep;
new String:listPropmenus[12][16];
new bool:telOn1;
new bool:telOn2;
new bool:telOn3;
new bool:telOn4;
new secondeEvent;
new String:sounddata[7][32] =
{
    "weapons/physcannon/physcannon_drop.wav",
    "weapons/physcannon/physcannon_pickup.wav",
    "weapons/physcannon/hold_loop.wav",
    "weapons/physcannon/superphys_launch1.wav",
    "weapons/physcannon/superphys_launch2.wav",
    "weapons/physcannon/superphys_launch3.wav",
    "weapons/physcannon/superphys_launch4.wav"
}
new Handle:cvar_maxpickupdistance;
new Handle:cvar_grabforcemultiply;
new Handle:cvar_grab_delay;
new Handle:cvar_grab_defaultdistance;
new Handle:cvar_strictmousecontrol;
new Handle:cvar_enablesound;
new Handle:cvar_blueteam_enable;
new Handle:cvar_redteam_enable;
new UserMsg:g_textmsg;
public Plugin:myinfo =
{
    name = "Roleplay FReZ",
    description = "Roleplay FReZ (Devenez le plus riche de la ville)",
    author = "Thieus",
    version = "1.0",
    url = "http://teamfrez.com"
};
public __ext_core_SetNTVOptional()
{
    MarkNativeAsOptional("GetFeatureStatus");
    MarkNativeAsOptional("RequireFeature");
    MarkNativeAsOptional("AddCommandListener");
    MarkNativeAsOptional("RemoveCommandListener");
    VerifyCoreVersion();
    return 0;
}

Float:operator-(Float:)(Float:oper)
{
    return oper ^ 0;
}

Float:operator*(Float:,_:)(Float:oper1, oper2)
{
    return FloatMul(oper1, float(oper2));
}

Float:operator/(Float:,_:)(Float:oper1, oper2)
{
    return FloatDiv(oper1, float(oper2));
}

Float:operator/(_:,Float:)(oper1, Float:oper2)
{
    return FloatDiv(float(oper1), oper2);
}

Float:operator-(Float:,_:)(Float:oper1, oper2)
{
    return FloatSub(oper1, float(oper2));
}

bool:operator==(Float:,Float:)(Float:oper1, Float:oper2)
{
    return FloatCompare(oper1, oper2) == 0;
}

bool:operator>(Float:,Float:)(Float:oper1, Float:oper2)
{
    return FloatCompare(oper1, oper2) > 0;
}

bool:operator<=(Float:,Float:)(Float:oper1, Float:oper2)
{
    return FloatCompare(oper1, oper2) <= 0;
}


/* ERROR! unknown operator */
 function "RadToDeg" (number 9)
AddVectors(Float:vec1[3], Float:vec2[3], Float:result[3])
{
    result[0] = FloatAdd(vec1[0], vec2[0]);
    result[4] = FloatAdd(vec1[4], vec2[4]);
    result[8] = FloatAdd(vec1[8], vec2[8]);
    return 0;
}

ScaleVector(Float:vec[3], Float:scale)
{
    new var1 = vec;
    var1[0] = FloatMul(var1[0], scale);
    new var2 = vec[4];
    var2 = FloatMul(var2, scale);
    new var3 = vec[8];
    var3 = FloatMul(var3, scale);
    return 0;
}

MakeVectorFromPoints(Float:pt1[3], Float:pt2[3], Float:output[3])
{
    output[0] = FloatSub(pt2[0], pt1[0]);
    output[4] = FloatSub(pt2[4], pt1[4]);
    output[8] = FloatSub(pt2[8], pt1[8]);
    return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
    return strcmp(str1, str2, caseSensitive) == 0;
}

ExplodeString(String:text[], String:split[], String:buffers[][], maxStrings, maxStringLength)
{
    new reloc_idx = 0;
    new idx = 0;
    new total = 0;
    new var1;
    if (maxStrings < 1) {
        return 0;
    }
    new var3 = SplitString(text[reloc_idx], split, buffers[total], maxStringLength);
    idx = var3;
    while (var3 != -1) {
        reloc_idx = idx + reloc_idx;
        if (text[reloc_idx]) {
            total++;
            if (total >= maxStrings) {
                return total;
            }
        }
        new var2;
        if (text[reloc_idx]) {
            total++;
            strcopy(buffers[total], maxStringLength, text[reloc_idx]);
        }
        return total;
    }
    new var2;
    if (text[reloc_idx]) {
        total++;
        strcopy(buffers[total], maxStringLength, text[reloc_idx]);
    }
    return total;
}

Handle:CreateDataTimer(Float:interval, Timer:func, &Handle:datapack, flags)
{
    datapack = CreateDataPack();
    flags |= 512;
    return CreateTimer(interval, func, datapack, flags);
}

PrintToChatAll(String:format[])
{
    new maxClients = GetMaxClients();
    decl String:buffer[192];
    new i = 1;
    while (i <= maxClients) {
        if (IsClientInGame(i)) {
            SetGlobalTransTarget(i);
            VFormat(buffer, 192, format, 2);
            PrintToChat(i, "%s", buffer);
            i++;
        }
        i++;
    }
    return 0;
}

GetEntSendPropOffs(ent, String:prop[], bool:actual)
{
    decl String:cls[64];
    if (!GetEntityNetClass(ent, cls, 64)) {
        return -1;
    }
    if (actual) {
        return FindSendPropInfo(cls, prop, 0, 0, 0);
    }
    return FindSendPropOffs(cls, prop);
}

SetEntityRenderColor(entity, r, g, b, a)
{
    static bool:gotconfig;
    static String:prop[8];
    if (!gotconfig) {
        new Handle:gc = LoadGameConfigFile("core.games");
        new bool:exists = GameConfGetKeyValue(gc, "m_clrRender", "", 32);
        CloseHandle(gc);
        if (!exists) {
            strcopy("", 32, "m_clrRender");
        }
        __unk = 1;
    }
    new offset = GetEntSendPropOffs(entity, "", false);
    if (0 >= offset) {
        ThrowError("SetEntityRenderColor not supported by this mod");
    }
    SetEntData(entity, offset, r, 1, true);
    SetEntData(entity, offset + 1, g, 1, true);
    SetEntData(entity, offset + 2, b, 1, true);
    SetEntData(entity, offset + 3, a, 1, true);
    return 0;
}

SetEntityHealth(entity, amount)
{
    static bool:gotconfig;
    static String:prop[8];
    if (!gotconfig) {
        new Handle:gc = LoadGameConfigFile("core.games");
        new bool:exists = GameConfGetKeyValue(gc, "m_iHealth", "", 32);
        CloseHandle(gc);
        if (!exists) {
            strcopy("", 32, "m_iHealth");
        }
        __unk = 1;
    }
    decl String:cls[64];
    new PropFieldType:type = 0;
    new offset = 0;
    if (!GetEntityNetClass(entity, cls, 64)) {
        ThrowError("SetEntityHealth not supported by this mod: Could not get serverclass name");
        return 0;
    }
    offset = FindSendPropInfo(cls, "", type, 0, 0);
    if (0 >= offset) {
        ThrowError("SetEntityHealth not supported by this mod");
        return 0;
    }
    if (type == PropFieldType:2) {
        SetEntDataFloat(entity, offset, float(amount), false);
    } else {
        SetEntProp(entity, PropType:0, "", amount, 4);
    }
    return 0;
}

GetClientButtons(client)
{
    static bool:gotconfig;
    static String:datamap[8];
    if (!gotconfig) {
        new Handle:gc = LoadGameConfigFile("core.games");
        new bool:exists = GameConfGetKeyValue(gc, "m_nButtons", "", 32);
        CloseHandle(gc);
        if (!exists) {
            strcopy("", 32, "m_nButtons");
        }
        __unk = 1;
    }
    return GetEntProp(client, PropType:1, "", 4);
}

EmitSoundToClient(client, String:sample[], entity, channel, level, flags, Float:volume, pitch, speakerentity, Float:origin[3], Float:dir[3], bool:updatePos, Float:soundtime)
{
    decl clients[1];
    clients[0] = client;
    new var1;
    if (entity == -2) {
        var1 = client;
    } else {
        var1 = entity;
    }
    entity = var1;
    EmitSound(clients, 1, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
    return 0;
}


/* ERROR! Unrecognized opcode: genarray_z */
 function "EmitSoundToAll" (number 22)
AddFileToDownloadsTable(String:filename[])
{
    static table = -1;
    if (table == -1) {
        table = FindStringTable("downloadables");
    }
    new bool:save = LockStringTables(false);
    AddToStringTable(table, filename, "", -1);
    LockStringTables(save);
    return 0;
}


/* ERROR! Unrecognized opcode: genarray_z */
 function "TE_SendToAll" (number 24)
TE_SetupSparks(Float:pos[3], Float:dir[3], Magnitude, TrailLength)
{
    TE_Start("Sparks");
    TE_WriteVector("m_vecOrigin[0]", pos);
    TE_WriteVector("m_vecDir", dir);
    TE_WriteNum("m_nMagnitude", Magnitude);
    TE_WriteNum("m_nTrailLength", TrailLength);
    return 0;
}

TE_SetupSmoke(Float:pos[3], Model, Float:Scale, FrameRate)
{
    TE_Start("Smoke");
    TE_WriteVector("m_vecOrigin", pos);
    TE_WriteNum("m_nModelIndex", Model);
    TE_WriteFloat("m_fScale", Scale);
    TE_WriteNum("m_nFrameRate", FrameRate);
    return 0;
}

TE_SetupExplosion(Float:pos[3], Model, Float:Scale, Framerate, Flags, Radius, Magnitude, Float:normal[3], MaterialType)
{
    TE_Start("Explosion");
    TE_WriteVector("m_vecOrigin[0]", pos);
    TE_WriteVector("m_vecNormal", normal);
    TE_WriteNum("m_nModelIndex", Model);
    TE_WriteFloat("m_fScale", Scale);
    TE_WriteNum("m_nFrameRate", Framerate);
    TE_WriteNum("m_nFlags", Flags);
    TE_WriteNum("m_nRadius", Radius);
    TE_WriteNum("m_nMagnitude", Magnitude);
    TE_WriteNum("m_chMaterialType", MaterialType);
    return 0;
}

TE_SetupBloodSprite(Float:pos[3], Float:dir[3], color[4], Size, SprayModel, BloodDropModel)
{
    TE_Start("Blood Sprite");
    TE_WriteVector("m_vecOrigin", pos);
    TE_WriteVector("m_vecDirection", dir);
    TE_WriteNum("r", color[0]);
    TE_WriteNum("g", color[4]);
    TE_WriteNum("b", color[8]);
    TE_WriteNum("a", color[12]);
    TE_WriteNum("m_nSize", Size);
    TE_WriteNum("m_nSprayModel", SprayModel);
    TE_WriteNum("m_nDropModel", BloodDropModel);
    return 0;
}

TE_SetupBeamRingPoint(Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, Color[4], Speed, Flags)
{
    TE_Start("BeamRingPoint");
    TE_WriteVector("m_vecCenter", center);
    TE_WriteFloat("m_flStartRadius", Start_Radius);
    TE_WriteFloat("m_flEndRadius", End_Radius);
    TE_WriteNum("m_nModelIndex", ModelIndex);
    TE_WriteNum("m_nHaloIndex", HaloIndex);
    TE_WriteNum("m_nStartFrame", StartFrame);
    TE_WriteNum("m_nFrameRate", FrameRate);
    TE_WriteFloat("m_fLife", Life);
    TE_WriteFloat("m_fWidth", Width);
    TE_WriteFloat("m_fEndWidth", Width);
    TE_WriteFloat("m_fAmplitude", Amplitude);
    TE_WriteNum("r", Color[0]);
    TE_WriteNum("g", Color[4]);
    TE_WriteNum("b", Color[8]);
    TE_WriteNum("a", Color[12]);
    TE_WriteNum("m_nSpeed", Speed);
    TE_WriteNum("m_nFlags", Flags);
    TE_WriteNum("m_nFadeLength", 0);
    return 0;
}

TE_SetupBeamPoints(Float:start[3], Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, Color[4], Speed)
{
    TE_Start("BeamPoints");
    TE_WriteVector("m_vecStartPoint", start);
    TE_WriteVector("m_vecEndPoint", end);
    TE_WriteNum("m_nModelIndex", ModelIndex);
    TE_WriteNum("m_nHaloIndex", HaloIndex);
    TE_WriteNum("m_nStartFrame", StartFrame);
    TE_WriteNum("m_nFrameRate", FrameRate);
    TE_WriteFloat("m_fLife", Life);
    TE_WriteFloat("m_fWidth", Width);
    TE_WriteFloat("m_fEndWidth", EndWidth);
    TE_WriteFloat("m_fAmplitude", Amplitude);
    TE_WriteNum("r", Color[0]);
    TE_WriteNum("g", Color[4]);
    TE_WriteNum("b", Color[8]);
    TE_WriteNum("a", Color[12]);
    TE_WriteNum("m_nSpeed", Speed);
    TE_WriteNum("m_nFadeLength", FadeLength);
    return 0;
}

bool:IsClientConnectedIngameAlive(client)
{
    if (IsClientConnectedIngame(client)) {
        new var1;
        if (IsPlayerAlive(client) == 1) {
            return true;
        }
        return false;
    }
    return false;
}

bool:IsClientConnectedIngame(client)
{
    new var1;
    if (client > 0) {
        if (IsClientInGame(client) == 1) {
            return true;
        }
        return false;
    }
    return false;
}

bool:GetClientAimPosition(client, Float:maxtracedistance, Float:resultvecpos[3], TraceEntityFilter:function, filter)
{
    decl Float:cleyepos[3];
    decl Float:cleyeangle[3];
    decl Float:eyeanglevector[3];
    GetClientEyePosition(client, cleyepos);
    GetClientEyeAngles(client, cleyeangle);
    new Handle:traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, 33570827, RayType:1, function, filter);
    if (TR_DidHit(traceresulthandle) == 1) {
        decl Float:endpos[3];
        TR_GetEndPosition(endpos, traceresulthandle);
        if (GetVectorDistance(cleyepos, endpos, false) <= maxtracedistance) {
            resultvecpos[0] = endpos[0];
            resultvecpos[4] = endpos[4];
            resultvecpos[8] = endpos[8];
            CloseHandle(traceresulthandle);
            return true;
        }
        GetAngleVectors(cleyeangle, eyeanglevector, NULL_VECTOR, NULL_VECTOR);
        NormalizeVector(eyeanglevector, eyeanglevector);
        ScaleVector(eyeanglevector, maxtracedistance);
        AddVectors(cleyepos, eyeanglevector, resultvecpos);
        CloseHandle(traceresulthandle);
        return true;
    }
    CloseHandle(traceresulthandle);
    return false;
}

GetClientAimEntity3(client, &Float:distancetoentity, Float:endpos[3])
{
    decl Float:cleyepos[3];
    decl Float:cleyeangle[3];
    GetClientEyePosition(client, cleyepos);
    GetClientEyeAngles(client, cleyeangle);
    new Handle:traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, 33570827, RayType:1, TraceEntityFilter:291, client);
    if (TR_DidHit(traceresulthandle) == 1) {
        TR_GetEndPosition(endpos, traceresulthandle);
        distancetoentity = GetVectorDistance(cleyepos, endpos, false);
        new entindextoreturn = TR_GetEntityIndex(traceresulthandle);
        CloseHandle(traceresulthandle);
        return entindextoreturn;
    }
    CloseHandle(traceresulthandle);
    return -1;
}

public bool:tracerayfilterdefault(entity, mask, data)
{
    if (data != entity) {
        return true;
    }
    return false;
}

public bool:tracerayfilteronlyone(entity, mask, data)
{
    new var1;
    if (data == entity) {
        return true;
    }
    return false;
}

public bool:tracerayfilterrocket(entity, mask, data)
{
    new owner = GetEntPropEnt(entity, PropType:0, "m_hOwnerEntity");
    new var1;
    if (data != entity) {
        return true;
    }
    return false;
}

public bool:tracerayfilternoplayer(entity, mask, data)
{
    if (!IsClientConnectedIngameAlive(entity)) {
        return true;
    }
    return false;
}

public bool:tracerayfilteronlyworld(entity, mask, data)
{
    if (entity) {
        return false;
    }
    return true;
}

matrix3x4_tFromVector(Float:fwd[3], Float:right[3], Float:up[3], Float:origin[3], matrix[12])
{
    matrix[0] = fwd[0];
    matrix[4] = right[0];
    matrix[8] = up[0];
    matrix[12] = origin[0];
    matrix[16] = fwd[4];
    matrix[20] = right[4];
    matrix[24] = up[4];
    matrix[28] = origin[4];
    matrix[32] = fwd[8];
    matrix[36] = right[8];
    matrix[40] = up[8];
    matrix[44] = origin[8];
    return 0;
}

matrix3x4FromAnglesNoOrigin(Float:angle[3], matrix[12])
{
    decl Float:fwd[3];
    decl Float:right[3];
    decl Float:up[3];
    decl Float:origin[3];
    GetAngleVectors(angle, fwd, right, up);
    matrix3x4_tFromVector(fwd, right, up, origin, matrix);
    return 0;
}

TransformAnglesToWorldSpace(Float:inputangle[3], Float:outputangle[3], parentmatrix[12])
{
    decl angtoparent[12];
    decl angtoworld[12];
    matrix3x4FromAnglesNoOrigin(inputangle, angtoparent);
    ConcatTransforms(parentmatrix, angtoparent, angtoworld);
    MatrixAngles(angtoworld, outputangle);
    return 0;
}

ConcatTransforms(in1[12], in2[12], out[12])
{
    out[0] = FloatAdd(FloatAdd(FloatMul(in1[0], in2[0]), FloatMul(in1[4], in2[16])), FloatMul(in1[8], in2[32]));
    out[4] = FloatAdd(FloatAdd(FloatMul(in1[0], in2[4]), FloatMul(in1[4], in2[20])), FloatMul(in1[8], in2[36]));
    out[8] = FloatAdd(FloatAdd(FloatMul(in1[0], in2[8]), FloatMul(in1[4], in2[24])), FloatMul(in1[8], in2[40]));
    out[12] = FloatAdd(FloatAdd(FloatAdd(FloatMul(in1[0], in2[12]), FloatMul(in1[4], in2[28])), FloatMul(in1[8], in2[44])), in1[12]);
    out[16] = FloatAdd(FloatAdd(FloatMul(in1[16], in2[0]), FloatMul(in1[20], in2[16])), FloatMul(in1[24], in2[32]));
    out[20] = FloatAdd(FloatAdd(FloatMul(in1[16], in2[4]), FloatMul(in1[20], in2[20])), FloatMul(in1[24], in2[36]));
    out[24] = FloatAdd(FloatAdd(FloatMul(in1[16], in2[8]), FloatMul(in1[20], in2[24])), FloatMul(in1[24], in2[40]));
    out[28] = FloatAdd(FloatAdd(FloatAdd(FloatMul(in1[16], in2[12]), FloatMul(in1[20], in2[28])), FloatMul(in1[24], in2[44])), in1[28]);
    out[32] = FloatAdd(FloatAdd(FloatMul(in1[32], in2[0]), FloatMul(in1[36], in2[16])), FloatMul(in1[40], in2[32]));
    out[36] = FloatAdd(FloatAdd(FloatMul(in1[32], in2[4]), FloatMul(in1[36], in2[20])), FloatMul(in1[40], in2[36]));
    out[40] = FloatAdd(FloatAdd(FloatMul(in1[32], in2[8]), FloatMul(in1[36], in2[24])), FloatMul(in1[40], in2[40]));
    out[44] = FloatAdd(FloatAdd(FloatAdd(FloatMul(in1[32], in2[12]), FloatMul(in1[36], in2[28])), FloatMul(in1[40], in2[44])), in1[44]);
    return 0;
}


/* ERROR! unknown operator */
 function "MatrixAngles" (number 44)
TransformAnglesToLocalSpace(Float:angle[3], Float:out[3], parentMatrix[12])
{
    decl angToWorld[12];
    decl worldToParent[12];
    decl localMatrix[12];
    MatrixInvert(parentMatrix, worldToParent);
    matrix3x4FromAnglesNoOrigin(angle, angToWorld);
    ConcatTransforms(worldToParent, angToWorld, localMatrix);
    MatrixAngles(localMatrix, out);
    return 0;
}


/* ERROR! unknown operator */
 function "MatrixInvert" (number 46)
ZeroVector(Float:vector[3])
{
    vector[0] = 0;
    vector[4] = 0;
    vector[8] = 0;
    return 0;
}

Log(String:pluginName[32], String:newLine[256])
{
    decl String:localBuffer[256];
    decl String:dateToday[64];
    FormatTime(dateToday, 64, "%Y-%m-%d", GetTime({0,0}));
    Format(localBuffer, 256, "cfg/roleplay/logs/%s.txt", dateToday);
    new Handle:g_FileLog = OpenFile(localBuffer, "a+");
    if (g_FileLog) {
        FormatTime(dateToday, 64, "%H:%M:%S", GetTime({0,0}));
        VFormat(localBuffer, 256, newLine, 3);
        WriteFileLine(g_FileLog, "[%s] [%s] %s\r", pluginName, dateToday, localBuffer);
        PrintToServer("# [HnS - %s] [%s] %s", pluginName, dateToday, localBuffer);
        CloseHandle(g_FileLog);
        g_FileLog = 0;
        return 0;
    }
    PrintToServer("# Impossible to acces to cfg/roleplay/logs/%s.txt file", dateToday);
    LogMessage("Impossible to acces to cfg/roleplay/logs/%s.txt file !", dateToday);
    return 0;
}

CreationDatabaseRp()
{
    if (db) {
        decl String:erreur[256];
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Player ( `steamid` VARCHAR(20) NOT NULL PRIMARY KEY, `pseudo` VARCHAR(40) NOT NULL, `salaire_sup` INTEGER DEFAULT '0', `cash` INTEGER DEFAULT '10000', `bank` INTEGER DEFAULT '0', `vente_moi` INTEGER DEFAULT '0', `vente_annee` INTEGER DEFAULT '0', `team` INTEGER DEFAULT '2', `id_metier` INTEGER DEFAULT '1', `skins` VARCHAR(40) DEFAULT 't_leet', `level_knife` INTEGER DEFAULT '0', `permi_pri` BOOLEAN DEFAULT '0', `permi_sec` BOOLEAN DEFAULT '0', `in_jail` BOOLEAN DEFAULT '0', `time_jail` INTEGER DEFAULT '0', `matuer` VARCHAR(40) DEFAULT 'Aucun', `jaituer` VARCHAR(40) DEFAULT 'Aucun', `tempspasse` INTEGER DEFAULT '0', `depobank` BOOLEAN DEFAULT '0', `objetsac` VARCHAR(90) DEFAULT '0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0', `objetbank` VARCHAR(90) DEFAULT '0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0', `cartecredit` BOOLEAN DEFAULT '0', `ribebank` BOOLEAN DEFAULT '0') ", -1)) {
            SQL_GetError(db, erreur, 255);
            Log("RolePlay Admin", "Impossible de cree la table player ->erreur : '%s'", erreur);
        }
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Bossjob ( `id_boss` INTEGER PRIMARY KEY AUTO_INCREMENT, `st_job0` VARCHAR(20) NOT NULL, `id_metier` INTEGER DEFAULT '0', `capital_groupe` INTEGER DEFAULT '0', `impot` INTEGER DEFAULT '0', `st_job1` VARCHAR(20) DEFAULT 'Aucun', `st_job2` VARCHAR(20) DEFAULT 'Aucun', `st_job3` VARCHAR(20) DEFAULT 'Aucun', `st_job4` VARCHAR(20) DEFAULT 'Aucun', `vente_npc_moi` INTEGER DEFAULT '0', `vente_npc_annee` INTEGER DEFAULT '0' ) ", -1)) {
            SQL_GetError(db, erreur, 255);
            Log("RolePlay Admin", "Impossible de cree la table Bossjob ->erreur : '%s'", erreur);
        }
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Porte ( `id_porte` INTEGER PRIMARY KEY NOT NULL, `lentite` INTEGER, `nom_porte` VARCHAR(32), `proba` INTEGER, `id_associe` INTEGER NOT NULL DEFAULT '1', `prix_porte` INTEGER, `location` INTEGER DEFAULT '0', `st_id0` VARCHAR(20) DEFAULT 'Aucun', `pseudo0` VARCHAR(32) DEFAULT 'Aucun', `st_id1` VARCHAR(20) DEFAULT 'Aucun', `pseudo1` VARCHAR(32) DEFAULT 'Aucun', `st_id2` VARCHAR(20) DEFAULT 'Aucun', `pseudo2` VARCHAR(32) DEFAULT 'Aucun', `st_id3` VARCHAR(20) DEFAULT 'Aucun', `pseudo3` VARCHAR(32) DEFAULT 'Aucun', `st_id4` VARCHAR(20) DEFAULT 'Aucun', `pseudo4` VARCHAR(32) DEFAULT 'Aucun' ) ", -1)) {
            SQL_GetError(db, erreur, 255);
            Log("RolePlay Admin", "Impossible de cree la table Porte ->erreur : '%s'", erreur);
        }
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Metier ( `id_metier` INTEGER PRIMARY KEY NOT NULL, `nom_metier` VARCHAR(32), `salaire_mini` INTEGER, `metier_chef` BOOLEAN, `id_associe` INTEGER ) ", -1)) {
            SQL_GetError(db, erreur, 255);
            Log("RolePlay Admin", "Impossible de cree la table Porte ->erreur : '%s'", erreur);
        }
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Objets ( `id_objet` INTEGER PRIMARY KEY NOT NULL, `nom_objet` VARCHAR(32), `effet` INTEGER, `fonction` VARCHAR(32), `prix` INTEGER, `id_associe` INTEGER ) ", -1)) {
            SQL_GetError(db, erreur, 255);
            Log("RolePlay Admin", "Impossible de cree la table Porte ->erreur : '%s'", erreur);
        }
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Capital ( `id_capital` INTEGER PRIMARY KEY NOT NULL, `nom_capital` VARCHAR(32), `total_capital` INTEGER DEFAULT '0' NOT NULL, `id_metier_assoc` INTEGER ) ", -1)) {
            SQL_GetError(db, erreur, 255);
            Log("RolePlay Admin", "Impossible de cree la table Capital ->erreur : '%s'", erreur);
        }
        if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Playersup ( `steamid` VARCHAR(20) NOT NULL PRIMARY KEY, `la_precision` INTEGER DEFAULT '0', `nbr_tuer` INTEGER DEFAULT '0', `totalKill` INTEGER DEFAULT '0', `nbr_mort` INTEGER DEFAULT '0', `vaccinpoison` BOOLEAN DEFAULT '0', `empoisonne` BOOLEAN DEFAULT '0') ", -1)) {
            SQL_GetError(db, erreur, 255);
            Log("RolePlay Admin", "Impossible de cree la table player ->erreur : '%s'", erreur);
        }
        return 0;
    }
    return 0;
}

sauvegarderInfosClient(client)
{
    if (db) {
        decl String:steamid[32];
        GetClientAuthString(client, steamid, 32);
        decl String:clientName[32];
        GetClientName(client, clientName, 32);
        decl String:req[512];
        decl String:error[256];
        if (!updateUser) {
            Format(req, 512, "UPDATE Player SET pseudo = ?, team = ?, cash = ?, bank = ?, level_knife = ?, permi_pri = ?, permi_sec = ?, in_jail = ?, time_jail = ?, matuer = ?, jaituer = ?, tempspasse = ?, depobank = ?, objetsac = ?, objetbank = ?, cartecredit = ?, ribebank = ? WHERE steamid = ?");
            updateUser = SQL_PrepareQuery(db, req, error, 255);
            if (updateUser) {
            } else {
                PrintToChatAll(" impossible de update les infos d'un joueur");
                Log("Roleplay Admin", "Impossible de modifier les infos d'un joueur dans la DB (error: %s) (req: '%s')", error, req);
                return 0;
            }
        }
        SQL_BindParamString(updateUser, 0, clientName, false);
        SQL_BindParamInt(updateUser, 1, clientTeam[client][0][0], false);
        SQL_BindParamInt(updateUser, 2, clientCash[client][0][0], true);
        SQL_BindParamInt(updateUser, 3, clientBank[client][0][0], true);
        SQL_BindParamInt(updateUser, 4, clientLevelKnife[client][0][0], false);
        SQL_BindParamInt(updateUser, 5, clientPermiPri[client][0][0], false);
        SQL_BindParamInt(updateUser, 6, clientPermiSec[client][0][0], false);
        SQL_BindParamInt(updateUser, 7, clientInJail[client][0][0], false);
        SQL_BindParamInt(updateUser, 8, clientTimeInJail[client][0][0], true);
        SQL_BindParamString(updateUser, 9, clientMaTuer[client][0][0], false);
        SQL_BindParamString(updateUser, 10, clientJaiTuer[client][0][0], false);
        SQL_BindParamInt(updateUser, 11, clientTempsPasse[client][0][0], true);
        SQL_BindParamInt(updateUser, 12, clientDepoBank[client][0][0], false);
        decl String:objets[128];
        Format(objets, 127, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", clientNbr1[client], clientItem1[client], clientNbr2[client], clientItem2[client], clientNbr3[client], clientItem3[client], clientNbr4[client], clientItem4[client], clientNbr5[client], clientItem5[client], clientNbr6[client], clientItem6[client], clientNbr7[client], clientItem7[client], clientNbr8[client], clientItem8[client], clientNbr9[client], clientItem9[client], clientNbr10[client], clientItem10[client]);
        SQL_BindParamString(updateUser, 13, objets, false);
        SQL_BindParamString(updateUser, 14, clientObjetBank[client][0][0], false);
        SQL_BindParamInt(updateUser, 15, clientCarteCredit[client][0][0], false);
        SQL_BindParamInt(updateUser, 16, clientRibe[client][0][0], false);
        SQL_BindParamString(updateUser, 17, steamid, false);
        decl String:errur[256];
        if (!SQL_Execute(updateUser)) {
            PrintToChatAll(" impossible de sauvegarder dans la DB");
            SQL_GetError(db, errur, 255);
            Log("RolePlay Admin", "impossible de sauvegarder les infos de %s dans player -> req: %s |||| erreur : %s", clientName, req, errur);
            return 0;
        }
        decl String:req2[256];
        decl String:errr[256];
        if (!updateUser2) {
            Format(req2, 256, "UPDATE Playersup SET la_precision = ?, nbr_tuer = ?, nbr_mort = ?, totalKill = ?, vaccinpoison = ?, empoisonne = ? WHERE steamid = ? ");
            updateUser2 = SQL_PrepareQuery(db, req2, errr, 255);
            if (updateUser2) {
            } else {
                PrintToChatAll(" impossible de update les infos d'un joueur N");
                Log("Roleplay Admin", "Impossible de preparer la req2 updateUser2 (error: %s) (req2: %s)", errr, req2);
                return 0;
            }
        }
        SQL_BindParamInt(updateUser2, 0, clientPrecision[client][0][0], false);
        SQL_BindParamInt(updateUser2, 1, clientKill[client][0][0], false);
        SQL_BindParamInt(updateUser2, 2, clientDead[client][0][0], false);
        SQL_BindParamInt(updateUser2, 3, clientTotalKill[client][0][0], false);
        SQL_BindParamInt(updateUser2, 4, clientVaccinPoison[client][0][0], false);
        SQL_BindParamInt(updateUser2, 5, clientEmpoissone[client][0][0], false);
        SQL_BindParamString(updateUser2, 6, steamid, false);
        if (!SQL_Execute(updateUser2)) {
            PrintToChatAll(" impossible de sauvegarder dans la DB N");
            SQL_GetError(db, errur, 255);
            Log("RolePlay Admin", "impossible de sauvegarder les infos de %s dans player -> req: '%s' |||| erreur : %s", clientName, req, errur);
            return 0;
        }
        Log("Roleplay FReZ", "Les donn‚es de %s sont sauvegarder Steam : %s", clientName, steamid);
        return 0;
    }
    return 0;
}

sauvegardeObjetEtCash(client)
{
    if (db) {
        decl String:steamid[32];
        GetClientAuthString(client, steamid, 32);
        decl String:clientName[32];
        GetClientName(client, clientName, 32);
        decl String:req[512];
        decl String:error[256];
        if (!updateUser5) {
            Format(req, 512, "UPDATE Player SET cash = ?, bank = ?, objetsac = ?, objetbank = ? WHERE steamid = ?");
            updateUser5 = SQL_PrepareQuery(db, req, error, 255);
            if (updateUser5) {
            } else {
                PrintToChatAll(" impossible de update les infos d'un joueur");
                Log("Roleplay Admin", "Impossible de modifier les infos d'un joueur dans la DB (error: %s) (req: '%s')", error, req);
                return 0;
            }
        }
        SQL_BindParamInt(updateUser5, 0, clientCash[client][0][0], true);
        SQL_BindParamInt(updateUser5, 1, clientBank[client][0][0], true);
        decl String:objets[128];
        Format(objets, 127, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", clientNbr1[client], clientItem1[client], clientNbr2[client], clientItem2[client], clientNbr3[client], clientItem3[client], clientNbr4[client], clientItem4[client], clientNbr5[client], clientItem5[client], clientNbr6[client], clientItem6[client], clientNbr7[client], clientItem7[client], clientNbr8[client], clientItem8[client], clientNbr9[client], clientItem9[client], clientNbr10[client], clientItem10[client]);
        SQL_BindParamString(updateUser5, 2, objets, false);
        SQL_BindParamString(updateUser5, 3, clientObjetBank[client][0][0], false);
        SQL_BindParamString(updateUser5, 4, steamid, false);
        decl String:errur[256];
        if (!SQL_Execute(updateUser5)) {
            PrintToChatAll(" impossible de sauvegarder dans la DB");
            SQL_GetError(db, errur, 255);
            Log("RolePlay Admin", "impossible de sauvegarder les infos de %s dans player(cash et objet) -> req: %s |||| erreur : %s", clientName, req, errur);
            return 0;
        }
        return 0;
    }
    return 0;
}

sauvegarderArgentClient(client)
{
    if (db) {
        decl String:steamid[32];
        GetClientAuthString(client, steamid, 32);
        decl String:clientName[32];
        GetClientName(client, clientName, 32);
        decl String:req[512];
        decl String:error[256];
        if (!updateUser3) {
            Format(req, 512, "UPDATE Player SET cash = ?, bank = ? WHERE steamid = ?");
            updateUser3 = SQL_PrepareQuery(db, req, error, 255);
            if (updateUser3) {
            } else {
                PrintToChatAll(" impossible de update les infos d'un joueur juste pour l'argent");
                Log("Roleplay Admin", "Impossible de modifier les infos d'un joueur dans la DB (error: %s) (req: '%s')", error, req);
                return 0;
            }
        }
        SQL_BindParamInt(updateUser3, 0, clientCash[client][0][0], true);
        SQL_BindParamInt(updateUser3, 1, clientBank[client][0][0], true);
        SQL_BindParamString(updateUser3, 2, steamid, false);
        decl String:errur[256];
        if (!SQL_Execute(updateUser3)) {
            PrintToChatAll(" impossible de sauvegarder dans la DB");
            SQL_GetError(db, errur, 255);
            Log("RolePlay Admin", "impossible de sauvegarder les infos de %s dans player -> req: %s |||| erreur : %s", clientName, req, errur);
            return 0;
        }
        return 0;
    }
    return 0;
}

sauvegarderObjetSac(client)
{
    if (db) {
        decl String:steamid[32];
        GetClientAuthString(client, steamid, 32);
        decl String:clientName[32];
        GetClientName(client, clientName, 32);
        decl String:req[512];
        decl String:error[256];
        if (!updateUser4) {
            Format(req, 512, "UPDATE Player SET objetsac = ?, objetbank = ? WHERE steamid = ?");
            updateUser4 = SQL_PrepareQuery(db, req, error, 255);
            if (updateUser4) {
            } else {
                PrintToChatAll(" impossible de update les infos d'un joueur");
                Log("Roleplay Admin", "Impossible de modifier les infos d'un joueur dans la DB (error: %s) (req: '%s')", error, req);
                return 0;
            }
        }
        decl String:objets[128];
        Format(objets, 127, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", clientNbr1[client], clientItem1[client], clientNbr2[client], clientItem2[client], clientNbr3[client], clientItem3[client], clientNbr4[client], clientItem4[client], clientNbr5[client], clientItem5[client], clientNbr6[client], clientItem6[client], clientNbr7[client], clientItem7[client], clientNbr8[client], clientItem8[client], clientNbr9[client], clientItem9[client], clientNbr10[client], clientItem10[client]);
        SQL_BindParamString(updateUser4, 0, objets, false);
        SQL_BindParamString(updateUser4, 1, clientObjetBank[client][0][0], false);
        SQL_BindParamString(updateUser4, 2, steamid, false);
        decl String:errur[256];
        if (!SQL_Execute(updateUser4)) {
            PrintToChatAll(" impossible de sauvegarder dans la DB");
            SQL_GetError(db, errur, 255);
            Log("RolePlay Admin", "impossible de sauvegarder les infos de %s dans player(sauvegarde objets) -> req: %s |||| erreur : %s", clientName, req, errur);
            return 0;
        }
        return 0;
    }
    return 0;
}

ajouterNouveauJoueur(client, String:auth[])
{
    if (db) {
        decl String:error[256];
        decl String:clientName[32];
        GetClientName(client, clientName, 32);
        if (!insertNewUser) {
            insertNewUser = SQL_PrepareQuery(db, "INSERT INTO Player (steamid, pseudo) VALUES (?, ?)", error, 255);
            if (insertNewUser) {
            } else {
                Log("Roleplay Admin", "Impossible d'inserer un nouveau joueur dans la DB (error: %s)", error);
            }
        }
        if (!insertNewUser2) {
            insertNewUser2 = SQL_PrepareQuery(db, "INSERT INTO Playersup (steamid) VALUES (?)", error, 255);
            if (insertNewUser2) {
            } else {
                Log("Roleplay Admin", "Impossible d'inserer un nouveau joueur dans la DB Playersup (error: %s)", error);
            }
        }
        SQL_BindParamString(insertNewUser, 0, auth, false);
        SQL_BindParamString(insertNewUser, 1, clientName, false);
        SQL_BindParamString(insertNewUser2, 0, auth, false);
        new var1;
        if (SQL_Execute(insertNewUser)) {
            strcopy(clientPseudo[client][0][0], 32, clientName);
            clientTeam[client] = 2;
            strcopy(clientSkin[client][0][0], 32, "t_leet");
            strcopy(clientMaTuer[client][0][0], 32, "Aucun");
            strcopy(clientJaiTuer[client][0][0], 32, "Aucun");
            clientIdMetier[client] = 1;
            clientCash[client] = 10000;
            clientBank[client] = 0;
            clientLevelKnife[client] = 0;
            clientPermiPri[client] = 0;
            clientPermiSec[client] = 0;
            clientInJail[client] = 0;
            clientTimeInJail[client] = 0;
            clientFermeture[client] = 60;
            clientTempsPasse[client] = 0;
            grenadeNapalm[client] = 0;
            clientCutNapalm[client] = 0;
            clientPrecision[client] = 0;
            clientKill[client] = 0;
            clientDead[client] = 0;
            clientTotalKill[client] = 0;
            clientNbr1[client] = 0;
            clientItem1[client] = 0;
            clientNbr2[client] = 0;
            clientItem2[client] = 0;
            clientNbr3[client] = 0;
            clientItem3[client] = 0;
            clientNbr4[client] = 0;
            clientItem4[client] = 0;
            clientNbr5[client] = 0;
            clientItem5[client] = 0;
            clientNbr6[client] = 0;
            clientItem6[client] = 0;
            clientNbr7[client] = 0;
            clientItem7[client] = 0;
            clientNbr8[client] = 0;
            clientItem8[client] = 0;
            clientNbr9[client] = 0;
            clientItem9[client] = 0;
            clientNbr10[client] = 0;
            clientItem10[client] = 0;
            buttondelay[client] = 0;
            clientDepoBank[client] = 0;
            strcopy(clientObjetBank[client][0][0], 90, "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0");
            clientCarteCredit[client] = 0;
            clientRibe[client] = 0;
            clientVaccinPoison[client] = 0;
            clientEmpoissone[client] = 0;
            Log("Roleplay FReZ", "Un nouveau Joueur … rejoin le serveur : %s : %s", clientName, auth);
            PrintToChatAll("%s Un nouveau citoyen s'appelant %s viens de rejoindre la ville", 50940, clientName);
        } else {
            ajouterJoueurDb(client, auth);
        }
        return 0;
    }
    return 0;
}

ajouterJoueurDb(client, String:auth[])
{
    if (db) {
        decl String:error[256];
        decl String:clientName[32];
        GetClientName(client, clientName, 32);
        decl String:rek[512];
        Format(rek, 512, "SELECT team, id_metier, skins, cash, bank, level_knife, permi_pri, permi_sec, in_jail, time_jail, matuer, jaituer, tempspasse, depobank, objetsac, objetbank, cartecredit, ribebank FROM Player WHERE steamid = '%s'", auth);
        new Handle:query = SQL_Query(db, rek, -1);
        if (query) {
            strcopy(clientPseudo[client][0][0], 32, clientName);
            if (SQL_FetchRow(query)) {
                clientTeam[client] = SQL_FetchInt(query, 0, 0);
                clientIdMetier[client] = SQL_FetchInt(query, 1, 0);
                SQL_FetchString(query, 2, clientSkin[client][0][0], 32, 0);
                clientCash[client] = SQL_FetchInt(query, 3, 0);
                clientBank[client] = SQL_FetchInt(query, 4, 0);
                clientLevelKnife[client] = SQL_FetchInt(query, 5, 0);
                clientPermiPri[client] = SQL_FetchBool(query, 6);
                clientPermiSec[client] = SQL_FetchBool(query, 7);
                clientInJail[client] = SQL_FetchBool(query, 8);
                clientTimeInJail[client] = SQL_FetchInt(query, 9, 0);
                clientFermeture[client] = 60;
                SQL_FetchString(query, 10, clientMaTuer[client][0][0], 32, 0);
                SQL_FetchString(query, 11, clientJaiTuer[client][0][0], 32, 0);
                clientTempsPasse[client] = SQL_FetchInt(query, 12, 0);
                clientDepoBank[client] = SQL_FetchBool(query, 13);
                SQL_FetchString(query, 15, clientObjetBank[client][0][0], 90, 0);
                clientCarteCredit[client] = SQL_FetchBool(query, 16);
                clientRibe[client] = SQL_FetchBool(query, 17);
                grenadeNapalm[client] = 0;
                clientCutNapalm[client] = 0;
                decl String:objets[128];
                SQL_FetchString(query, 14, objets, 127, 0);
                decl String:split[84][8];
                ExplodeString(objets, ",", split, 21, 5);
                clientNbr1[client] = StringToInt(split[0][split], 10);
                clientItem1[client] = StringToInt(split[4], 10);
                clientNbr2[client] = StringToInt(split[8], 10);
                clientItem2[client] = StringToInt(split[12], 10);
                clientNbr3[client] = StringToInt(split[16], 10);
                clientItem3[client] = StringToInt(split[20], 10);
                clientNbr4[client] = StringToInt(split[24], 10);
                clientItem4[client] = StringToInt(split[28], 10);
                clientNbr5[client] = StringToInt(split[32], 10);
                clientItem5[client] = StringToInt(split[36], 10);
                clientNbr6[client] = StringToInt(split[40], 10);
                clientItem6[client] = StringToInt(split[44], 10);
                clientNbr7[client] = StringToInt(split[48], 10);
                clientItem7[client] = StringToInt(split[52], 10);
                clientNbr8[client] = StringToInt(split[56], 10);
                clientItem8[client] = StringToInt(split[60], 10);
                clientNbr9[client] = StringToInt(split[64], 10);
                clientItem9[client] = StringToInt(split[68], 10);
                clientNbr10[client] = StringToInt(split[72], 10);
                clientItem10[client] = StringToInt(split[76], 10);
                decl String:rek2[512];
                Format(rek2, 512, "SELECT la_precision, nbr_tuer, nbr_mort, totalKill, vaccinpoison, empoisonne FROM Playersup WHERE steamid = '%s'", auth);
                new Handle:query2 = SQL_Query(db, rek2, -1);
                if (query2) {
                    if (SQL_FetchRow(query2)) {
                        clientPrecision[client] = SQL_FetchInt(query2, 0, 0);
                        clientKill[client] = SQL_FetchInt(query2, 1, 0);
                        clientDead[client] = SQL_FetchInt(query2, 2, 0);
                        clientTotalKill[client] = SQL_FetchInt(query2, 3, 0);
                        clientVaccinPoison[client] = SQL_FetchBool(query2, 4);
                        clientEmpoissone[client] = SQL_FetchBool(query2, 5);
                        buttondelay[client] = 0;
                        Log("Roleplay FReZ", "Le Joueur %s rejoin le serveur : %s", clientName, auth);
                        return 0;
                    }
                    Log("Roleplay Admin", "Impossible de select les infos players dans players N");
                    return 0;
                }
                SQL_GetError(db, error, 255);
                Log("Roleplay Admin", "Impossible de select dans Playersup les infos player-> error: %s", error);
                return 0;
            }
            Log("Roleplay Admin", "Impossible de select les infos players dans players");
            return 0;
        }
        SQL_GetError(db, error, 255);
        Log("Roleplay Admin", "Impossible de select dans player les infos player-> error: %s", error);
        return 0;
    }
    return 0;
}

bool:SQL_FetchBool(Handle:req, field)
{
    if (SQL_FetchInt(req, field, 0) == 1) {
        return true;
    }
    return false;
}

LoadKeyvalues()
{
    decl String:req[512];
    decl String:error[512];
    new Handle:query2 = 0;
    new i = 1;
    while (i < 84) {
        Format(req, 512, "SELECT nom_objet, effet, fonction, prix, id_associe FROM Objets WHERE id_objet = %d", i);
        query2 = SQL_Query(db, req, -1);
        if (query2) {
            if (SQL_FetchRow(query2)) {
                SQL_FetchString(query2, 0, objetNom[i][0][0], 32, 0);
                objetEffet[i] = SQL_FetchInt(query2, 1, 0);
                SQL_FetchString(query2, 2, objetFonction[i][0][0], 16, 0);
                objetPrix[i] = SQL_FetchInt(query2, 3, 0);
                objetIdAssoc[i] = SQL_FetchInt(query2, 4, 0);
                i++;
            }
            Log("Roleplay Admin", "Impossible de select les infos des objets i = %d", i);
            return 0;
        }
        SQL_GetError(db, error, 512);
        Log("Roleplay Admin", "Impossible de select dans Objets tout les objets-> error: %s", error);
        return 0;
    }
    new Handle:query = 0;
    new j = 1;
    while (j < 41) {
        Format(req, 512, "SELECT nom_metier, salaire_mini, metier_chef, id_associe FROM Metier WHERE id_metier = %d", j);
        query = SQL_Query(db, req, -1);
        if (query) {
            if (SQL_FetchRow(query)) {
                SQL_FetchString(query, 0, metierNom[j][0][0], 32, 0);
                metierFric[j] = SQL_FetchInt(query, 1, 0);
                metierChef[j] = SQL_FetchInt(query, 2, 0);
                metierIdAssoc[j] = SQL_FetchInt(query, 3, 0);
                j++;
            }
            Log("Roleplay Admin", "Impossible de select les infos metier dans metiers j = %d", j);
            return 0;
        }
        SQL_GetError(db, error, 512);
        Log("Roleplay Admin", "Impossible de select dans metier les noms des metiers, et le salaire-> error: %s", error);
        return 0;
    }
    return 0;
}

inListAdmin(client)
{
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new i = 0;
    while (i < 65) {
        if (StrEqual(steamid, ListeAdminRoleplay[i][0][0], true)) {
            return 1;
        }
        i++;
    }
    return 0;
}

InsereCapital()
{
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (1, 'Tr‚sorerie g‚n‚ral', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (2, 'L''hopital', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (3, 'Les pizzerias', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (4, 'Les moniteur de tir', 11)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (5, 'Les banquiers', 13)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (6, 'Les serruriers', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (7, 'Les couteliers', 17)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (8, 'Les armurier', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (9, 'Les chefs en explosif', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (10, 'Les d‚tectives', 23)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (11, 'Les chefs d''Ikea', 25)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (12, 'Les barmans', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (13, 'Les dealers', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (14, 'Les stylistes', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (15, 'Les Mac', 33)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (16, 'Les Mafieux FReZ', 35)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (17, 'Les Mafieux Italien', 37)", -1);
    SQL_FastQuery(db, "INSERT INTO Capital (id_capital, nom_capital, id_metier_assoc) VALUES (18, 'Les Mafieux Russe', 39)", -1);
    return 0;
}

InsereObjets()
{
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (1, 'Pizza Margherita', 20, 10, 'Hp', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (2, 'Pizza Milano', 50, 25, 'Hp', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (3, 'Pizza Formaggi', 75, 50, 'Hp', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (4, 'Pizza Plazza', 150, 100, 'Hp', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (5, 'Pizza Vegetarienne', 15, 2, 'Speed', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (6, 'Pizza Paysanne', 20, 4, 'Speed', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (7, 'Pizza Calzone', 20, 8, 'Grav', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (8, 'Pizza Buffalo', 35, 6, 'Grav', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (9, 'Pizza Reine', 40, 5, 'Grav', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (10, 'Shit', 20, 10, 'Hp', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (11, 'Beu', 50, 25, 'Hp', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (12, 'Hero', 75, 50, 'Hp', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (13, 'Coke', 150, 100, 'Hp', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (14, 'Estacy', 35, 3, 'Speed', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (15, 'Speed', 50, 6, 'Speed', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (16, 'Lsd', 35, 6, 'Grav', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (17, 'Doliprane', 20, 10, 'Hp', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (18, 'Mercurochrome', 50, 25, 'Hp', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (19, 'Efferalgan', 75, 50, 'Hp', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (20, 'Morfine', 150, 100, 'Hp', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (21, 'Smecta', 35, 3, 'Speed', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (22, 'VitamineC', 50, 6, 'Speed', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (23, 'Pillule', 15, 8, 'Grav', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (24, 'Viagra', 35, 5, 'Grav', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (25, 'Cafe', 15, 3, 'Speed', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (26, 'Coca Cola', 20, 4, 'Speed', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (27, 'Jus d Orange', 50, 6, 'Speed', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (28, 'Ice tea', 20, 8, 'Grav', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (29, 'Red bull', 35, 6, 'Grav', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (30, 'Orangina', 50, 5, 'Grav', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (31, 'Bierre', 20, 10, 'Hp', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (32, 'Vodka', 75, 50, 'Hp', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (33, 'Whisky', 150, 100, 'Hp', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (34, 'usp', 120, 1, 'ArSec', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (35, 'glock', 100, 1, 'ArSec', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (36, 'p228', 150, 1, 'ArSec', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (37, 'deagle', 200, 1, 'ArSec', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (38, 'fiveseven', 170, 1, 'ArSec', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (39, 'elite', 200, 1, 'ArSec', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (40, 'mac10', 210, 1, 'ArPri', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (41, 'tmp', 220, 1, 'ArPri', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (42, 'Fiole de pr‚cision', 40, 1, 'FP', 11)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (43, 'famas', 400, 1, 'ArPri', 23)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (44, 'scout', 600, 1, 'ArPri', 23)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (45, 'm4a1', 530, 1, 'ArPri', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (46, 'aug', 550, 1, 'ArPri', 35)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (47, 'g3sg1', 1500, 1, 'ArPri', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (48, 'awp', 2000, 1, 'ArPri', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (49, 'm3', 420, 1, 'ArPri', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (50, 'xm1014', 480, 1, 'ArPri', 37)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (51, 'mp5navy', 350, 1, 'ArPri', 35)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (52, 'ump45', 320, 1, 'ArPri', 37)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (53, 'p90', 390, 1, 'ArPri', 39)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (54, 'm249', 2400, 1, 'ArPri', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (55, 'galil', 380, 1, 'ArPri', 39)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (56, 'sg552', 1300, 1, 'ArPri', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (57, 'flashbang', 80, 1, 'ArPri', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (58, 'smokegrenade', 60, 1, 'ArPri', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (59, 'hegrenade', 60, 1, 'ArPri', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (60, 'Kevlar', 100, 1, 'ArPri', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (61, 'ak47', 500, 1, 'ArPri', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (62, 'Lame de couteau', 25, 1, 'Lame', 17)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (63, 'Lame Renforc‚e', 30, 1, 'LR', 17)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (64, 'Kit de crochetage', 200, 1, 'Porte', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (65, 'Habit 50 cent', 550, 1, 'Skins', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (66, 'Habit vin diesel', 600, 1, 'Skins', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (67, 'Habit blood 2', 450, 1, 'Skins', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (68, 'Habit crips 2', 450, 1, 'Skins', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (69, 'Habit nico bellic', 400, 1, 'Skins', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (70, 'Habit alice murray', 400, 1, 'Skins', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (71, 'Habit greaser', 500, 1, 'Skins', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (72, 'Renforce serrure N1 (1/4)', 300, 1, 'Niveau', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (73, 'Renforce serrure N2 (1/5)', 600, 2, 'Niveau', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (74, 'Renforce serrure N3 (1/6)', 900, 3, 'Niveau', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (75, 'Renforce serrure N4 (1/7)', 1200, 4, 'Niveau', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (76, 'Renforce serrure N5 (1/8)', 1500, 5, 'Niveau', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (77, 'Renforce serrure N6 (1/9)', 1800, 6, 'Niveau', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (78, 'Renforce serrure N7 (1/10)', 2100, 7, 'Niveau', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (79, 'c4', 650, 1, 'ArSec', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (80, 'Grenade Napalm', 100, 1, 'ArPri', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (81, 'Cut Napalm', 150, 40, 'sec', 17)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (82, 'Poison', 210, 1, 'Personne', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Objets (id_objet, nom_objet, prix, effet, fonction, id_associe) VALUES (83, 'Antidote', 190, 1, 'Personne', 6)", -1);
    return 0;
}

InsereMetier()
{
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (1, 'Sans emploi', 100, '0', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (2, 'Chef Police', 1000, '0', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (3, 'Agent du FBI', 370, '0', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (4, 'Policier', 310, '0', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (5, 'Gardien', 280, '0', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (6, 'Directeur hopital', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (7, 'Docteur', 100, '0', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (8, 'Infirmier', 100, '0', 6)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (9, 'Chef pizzeria', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (10, 'Pizzaiolo', 100, '0', 9)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (11, 'Chef moniteur de tir', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (12, 'Moniteur de tir', 100, '0', 11)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (13, 'Chef banquier', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (14, 'Banquier', 100, '0', 13)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (15, 'Chef serrurier', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (16, 'Serrurier', 100, '0', 15)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (17, 'Chef Coach', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (18, 'Coach', 100, '0', 17)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (19, 'Chef armurier', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (20, 'Armurier', 100, '0', 19)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (21, 'Chef en explosif', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (22, 'Vendeur explosif', 100, '0', 21)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (23, 'Chef d‚tective', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (24, 'D‚tective', 100, '0', 23)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (25, 'Chef Ikea', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (26, 'Vendeur Ikea', 100, '0', 25)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (27, 'Chef barman', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (28, 'Barman', 100, '0', 27)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (29, 'Chef dealer', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (30, 'Dealer', 100, '0', 29)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (31, 'Chef styliste', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (32, 'Styliste', 100, '0', 31)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (33, 'Mac', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (34, 'Prostitu‚e', 100, '0', 33)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (35, 'Chef Mafia Last', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (36, 'Mafieux Last', 100, '0', 35)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (37, 'Chef Mafia Italienne', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (38, 'Mafieux Italien', 100, '0', 37)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (39, 'Chef Mafia Russe', 100, '1', -1)", -1);
    SQL_FastQuery(db, "INSERT INTO Metier (id_metier, nom_metier, salaire_mini, metier_chef, id_associe) VALUES (40, 'Mafieux Russe', 100, '0', 39)", -1);
    return 0;
}

InserePorteDansladb()
{
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 0, 531, 'Appart H2', 3, 350)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 1, 496, 'H2-toilette', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 2, 495, 'H2-toilette2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 3, 494, 'H2-chambre', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 4, 625, 'Epicerie', 3, 250)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 5, 312, 'Appart Epic AP1', 3, 370)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 6, 307, 'Ap1-toilette', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 7, 296, 'Appart-Epic', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 8, 313, 'Appart Epic AP2', 3, 370)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 9, 318, 'AP2-toilette', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 10, 1083, 'Le Bar', 3, 400)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 11, 1084, 'Le Bar2', 3, 400)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 12, 809, 'Magasin IKEA', 3, 450)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 13, 808, 'IKEA-2', 3, 450)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 14, 546, 'BANK-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 15, 812, 'BANK-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 16, 811, 'La Banque', 3, 500)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 17, 602, 'Le FBI', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 18, 604, 'Le FBI-2', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 19, 605, 'Le FBI-3', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 20, 606, 'Le FBI-4', 6, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 21, 413, 'Appart H1', 3, 350)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 22, 437, 'H1-toilette', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 23, 436, 'H1-toilette2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 24, 435, 'H1-chambre', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 25, 525, 'Entrer Police', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 26, 537, 'Police-2', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 27, 536, 'Police-3', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 28, 262, 'Police-4', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 29, 263, 'Police-5', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 30, 498, 'Police-6', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 31, 530, 'Police-garage', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 32, 330, 'Magasin Ebay', 3, 350)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 33, 66, 'Magasin Microchip', 3, 350)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 34, 540, 'Tribunal-2', 6, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 35, 539, 'Tribunal-3', 6, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 36, 1261, 'Le tribunal', 6, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 37, 444, 'Stand-de-tir', 3, 550)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 38, 1082, 'Stand-de-tir-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 39, 1069, 'Stand-de-tir-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 40, 80, 'Garage-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 41, 81, 'Le garage', 3, 360)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 42, 934, 'Armurie', 3, 600)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 43, 935, 'Armurie-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 44, 939, 'Armerie-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 45, 940, 'Armerie-4', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 46, 941, 'Armerie-5', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 47, 408, 'Magasin Seven', 3, 280)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 48, 409, 'Magasin Seven-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 49, 1280, 'Appart Mafia Last', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 50, 1281, 'Appart Mafia Last-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 51, 1149, 'Disco-4', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 52, 1148, 'Disco-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 53, 1147, 'Disco-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 54, 1146, 'Disco-5', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 55, 1161, 'La DiscothŠque', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 56, 200, 'La pizzeria', 3, 325)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 57, 201, 'La pizzeria-2', 3, 325)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 58, 198, 'La pizzeria-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 59, 199, 'La pizzeria-4', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 60, 1066, 'Salle de sport', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 61, 1067, 'Sport-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 62, 1068, 'Sport-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 63, 235, 'Appart Mafia-Russe', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 64, 247, 'Appart Mafia-Russe2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 65, 248, 'Appart Mafia-Russe3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 66, 243, 'Appart Mafia-Russe4', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 67, 244, 'Appart Mafia-Russe5', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 68, 237, 'Appart Mafia-Russe6', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 69, 224, 'Appart Mafia-Russe7', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 70, 692, 'Le Carshop', 3, 450)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 71, 693, 'Le Carshop-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 72, 694, 'Le Carshop-G1', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 73, 695, 'Le Carshop-G2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 74, 697, 'Le Carshop-G3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 75, 696, 'Le Carshop-G4', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 76, 1120, 'La Mairie', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 77, 1121, 'La Mairie-1', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 78, 1123, 'La Mairie-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 79, 1122, 'La Mairie-4', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 80, 1136, 'La Mairie-5', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 81, 1141, 'La Mairie-6', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 82, 711, 'Appart Mafia-Italienne', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 83, 914, 'Appart Mafia-Italienne-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 84, 146, 'Appart-Jaune-1', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 85, 145, 'Appart-Jaune-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 86, 144, 'Appart-Jaune-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 87, 143, 'Appart-Jaune-4', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 88, 147, 'Appart-Jaune RDC', 3, 150)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 89, 148, 'Appart-rdch-2', 3, 150)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 90, 155, 'Appart Jaune Premier ‚tage', 3, 350)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 91, 157, 'Apart-pre-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 92, 156, 'Appart-pre-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 93, 153, 'Appart Jaune 2eme ‚tage', 3, 350)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 94, 154, 'Appart-deux-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 95, 152, 'Appart-deux-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 96, 597, 'Appart jaune 3eme', 3, 150)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 97, 447, 'Hospital', 3, 500)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 98, 1036, 'Hospital-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 99, 1035, 'Hospital-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 100, 967, 'Hospital-4', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 101, 295, 'Hospital-sal1', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 102, 460, 'H-apart-1', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 103, 459, 'H-apart-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 104, 453, 'H-apart-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 105, 1010, 'Hotel', 3, 700)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 106, 1009, 'Hotel-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 107, 968, 'Hotel-3', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 108, 969, 'Hotel porte Nø1', 3, 100)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 109, 973, 'Hotel-pre-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 110, 986, 'Hotel porte Nø2', 3, 100)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 111, 988, 'Hotel-deux-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 112, 978, 'Hotel porte Nø3', 3, 100)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 113, 977, 'Hotel-trois-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 114, 985, 'Hotel porte Nø4', 3, 100)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 115, 987, 'Hotel-quat-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 116, 989, 'Hotel porte Nø5', 3, 100)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 117, 994, 'Hotel-cinq-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 118, 990, 'Hotel porte Nø6', 3, 100)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 119, 996, 'Hotel-six-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 120, 992, 'Hotel porte Nø7', 3, 100)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 121, 993, 'Hotel-sept-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 122, 991, 'Hotel porte Nø8', 3, 100)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 123, 995, 'Hotel-huit-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 124, 1011, 'Hotel porte Nø9', 3, 200)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 125, 1014, 'Hotel-neuf-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 126, 1012, 'Hotel porte Nø10', 3, 200)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (1, 127, 1013, 'Hotel-dix-2', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 128, 966, 'Grille', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 129, 99, 'commissariat-1', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 130, 101, 'commissariat-2', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 131, 102, 'commissariat-3', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (3, 132, 100, 'commissariat-4', 4, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 133, 1065, 'seven-contoir', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 134, 1085, 'Bar-contoir', 3, 0)", -1);
    SQL_FastQuery(db, "INSERT INTO Porte (id_associe, id_porte, lentite, nom_porte, proba, prix_porte) VALUES (2, 135, 768, 'Ikea-contoir', 3, 0)", -1);
    return 0;
}

RecuperationDesPortes()
{
    if (db) {
        decl String:erreur[256];
        if (!selectDoor) {
            selectDoor = SQL_PrepareQuery(db, "SELECT lentite, nom_porte, proba, prix_porte, location, st_id0, pseudo0, st_id1, pseudo1, st_id2, pseudo2, st_id3,  pseudo3, st_id4, pseudo4, id_associe FROM Porte WHERE id_porte = ?", erreur, 255);
            if (selectDoor) {
            } else {
                Log("RolePlay Admin", "Impossible de preparer la requette pour preparer la requette ->erreur : %s", erreur);
                return 0;
            }
        }
        new i = 0;
        while (i < 136) {
            SQL_BindParamInt(selectDoor, 0, i, false);
            if (!SQL_Execute(selectDoor)) {
                SQL_GetError(db, erreur, 255);
                Log("RolePlay Admin", "impossible de select les infos d'une porte -> erreur : %s", erreur);
                return 0;
            }
            if (SQL_FetchRow(selectDoor)) {
                porteNumero[i] = SQL_FetchInt(selectDoor, 0, 0);
                SQL_FetchString(selectDoor, 1, porteNom[i][0][0], 137, 0);
                porteProba[i] = SQL_FetchInt(selectDoor, 2, 0);
                portePrix[i] = SQL_FetchInt(selectDoor, 3, 0);
                porteLocation[i] = SQL_FetchInt(selectDoor, 4, 0);
                porteIdAssocie[i] = SQL_FetchInt(selectDoor, 15, 0);
                SQL_FetchString(selectDoor, 5, porteProprio1[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 6, pseudoProprio1[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 7, porteProprio2[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 8, pseudoProprio2[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 9, porteProprio3[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 10, pseudoProprio3[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 11, porteProprio4[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 12, pseudoProprio4[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 13, porteProprio5[i][0][0], 137, 0);
                SQL_FetchString(selectDoor, 14, pseudoProprio5[i][0][0], 137, 0);
                i++;
            }
            i++;
        }
        return 0;
    }
    Log("Roleplay FReZ", "Impossible de connecter a la database");
    return 0;
}

public Action:VerrouillageDeTouteLesPortes(Handle:timer)
{
    new entity = 0;
    new i = 0;
    while (i < 137) {
        entity = porteNumero[i][0][0];
        AcceptEntityInput(entity, "close", -1, -1, 0);
        AcceptEntityInput(entity, "lock", -1, -1, 0);
        i++;
    }
    PrintToChatAll("%s Toutes les portes sont ferm‚es !", 152500);
    return Action:0;
}

RetirerUnDoubleDesCle(client)
{
    new entity = GetClientAimTarget(client, false);
    if (entity != -1) {
        new index = porteExisteDansLaDB(entity);
        if (index != -1) {
            decl String:steamid[32];
            GetClientAuthString(client, steamid, 32);
            if (StrEqual(porteProprio1[index][0][0], steamid, true)) {
                if (ProcheJoueurPorte(entity, client)) {
                    new Handle:g_MenuRetirCle = CreateMenu(MenuHandler:101, MenuAction:28);
                    SetMenuTitle(g_MenuRetirCle, "Choisir … qui voulez\nvous retirer\nun double des cl‚s");
                    decl String:buffer[32];
                    decl String:parametre[64];
                    if (!StrEqual(porteProprio2[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio2[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio2[index][0][0]);
                        AddMenuItem(g_MenuRetirCle, parametre, buffer, 0);
                    }
                    if (!StrEqual(porteProprio3[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio3[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio3[index][0][0]);
                        AddMenuItem(g_MenuRetirCle, parametre, buffer, 0);
                    }
                    if (!StrEqual(porteProprio4[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio4[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio4[index][0][0]);
                        AddMenuItem(g_MenuRetirCle, parametre, buffer, 0);
                    }
                    if (!StrEqual(porteProprio5[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio5[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio5[index][0][0]);
                        AddMenuItem(g_MenuRetirCle, parametre, buffer, 0);
                    }
                    if (!DisplayMenu(g_MenuRetirCle, client, 300)) {
                        PrintToChat(client, "%s Aucun double de cl‚s a ‚tait donn‚ !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Porte non enregistr‚e dans la DB !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous n'avez pas vis‚ une porte !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockRetirerCleUnJoueur(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[64];
    decl String:split[12][32];
    GetMenuItem(menu, choice, parametre, 64, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 32);
    new index = StringToInt(split[4], 10);
    if (JoueurProprio(index, split[0][split])) {
        new emplacement = PlaceDuSteamIDPorte(index, split[0][split]);
        if (0 < emplacement) {
            if (emplacement == 1) {
                PrintToChat(client, "%s %s n'as plus le double des cl‚s de cette porte !", "[Rp Magnetik : ->]", pseudoProprio1[index][0][0]);
            } else {
                if (emplacement == 2) {
                    PrintToChat(client, "%s %s n'as plus le double des cl‚s de cette porte !", "[Rp Magnetik : ->]", pseudoProprio2[index][0][0]);
                }
                if (emplacement == 3) {
                    PrintToChat(client, "%s %s n'as plus le double des cl‚s de cette porte !", "[Rp Magnetik : ->]", pseudoProprio3[index][0][0]);
                }
                if (emplacement == 4) {
                    PrintToChat(client, "%s %s n'as plus le double des cl‚s de cette porte !", "[Rp Magnetik : ->]", pseudoProprio4[index][0][0]);
                }
                if (emplacement == 5) {
                    PrintToChat(client, "%s %s n'as plus le double des cl‚s de cette porte !", "[Rp Magnetik : ->]", pseudoProprio5[index][0][0]);
                }
            }
            retirerSteamidPorte(emplacement, index);
        }
    }
    return 0;
}

retirerSteamidPorte(valeur, index)
{
    decl String:rek[512];
    if (valeur == 1) {
        Format(rek, 512, "UPDATE Porte SET st_id0 = st_id1, pseudo0 = pseudo1, st_id1 = st_id2, pseudo1 = pseudo2, st_id2 = st_id3, pseudo2 = pseudo3, st_id3 = st_id4, pseudo3 = pseudo4, st_id4 = 'Aucun', pseudo4 = 'Aucun' WHERE id_porte = %d", index);
        if (!SQL_FastQuery(db, rek, -1)) {
            decl String:error[256];
            SQL_GetError(db, error, 255);
            Log("RolePlay Admin", "impossible de update les porte (retirSteamidporte) door.sp V= 1 -> erreur : %s", error);
            return 0;
        }
        strcopy(porteProprio1[index][0][0], 32, porteProprio2[index][0][0]);
        strcopy(pseudoProprio1[index][0][0], 32, pseudoProprio2[index][0][0]);
        strcopy(porteProprio2[index][0][0], 32, porteProprio3[index][0][0]);
        strcopy(pseudoProprio2[index][0][0], 32, pseudoProprio3[index][0][0]);
        strcopy(porteProprio3[index][0][0], 32, porteProprio4[index][0][0]);
        strcopy(pseudoProprio3[index][0][0], 32, pseudoProprio4[index][0][0]);
        strcopy(porteProprio4[index][0][0], 32, porteProprio5[index][0][0]);
        strcopy(pseudoProprio4[index][0][0], 32, pseudoProprio5[index][0][0]);
        strcopy(porteProprio5[index][0][0], 32, "Aucun");
        strcopy(pseudoProprio5[index][0][0], 32, "Aucun");
    } else {
        if (valeur == 2) {
            Format(rek, 512, "UPDATE Porte SET  st_id1 = st_id2, pseudo1 = pseudo2, st_id2 = st_id3, pseudo2 = pseudo3, st_id3 = st_id4, pseudo3 = pseudo4, st_id4 = 'Aucun', pseudo4 = 'Aucun' WHERE id_porte = %d", index);
            if (!SQL_FastQuery(db, rek, -1)) {
                decl String:error[256];
                SQL_GetError(db, error, 255);
                Log("RolePlay Admin", "impossible de update les porte (retirSteamidporte) door.sp V= 2 -> erreur : %s", error);
                return 0;
            }
            strcopy(porteProprio2[index][0][0], 32, porteProprio3[index][0][0]);
            strcopy(pseudoProprio2[index][0][0], 32, pseudoProprio3[index][0][0]);
            strcopy(porteProprio3[index][0][0], 32, porteProprio4[index][0][0]);
            strcopy(pseudoProprio3[index][0][0], 32, pseudoProprio4[index][0][0]);
            strcopy(porteProprio4[index][0][0], 32, porteProprio5[index][0][0]);
            strcopy(pseudoProprio4[index][0][0], 32, pseudoProprio5[index][0][0]);
            strcopy(porteProprio5[index][0][0], 32, "Aucun");
            strcopy(pseudoProprio5[index][0][0], 32, "Aucun");
        }
        if (valeur == 3) {
            Format(rek, 512, "UPDATE Porte SET st_id2 = st_id3, pseudo2 = pseudo3, st_id3 = st_id4, pseudo3 = pseudo4, st_id4 = 'Aucun', pseudo4 = 'Aucun' WHERE id_porte = %d", index);
            if (!SQL_FastQuery(db, rek, -1)) {
                decl String:error[256];
                SQL_GetError(db, error, 255);
                Log("RolePlay Admin", "impossible de update les porte (retirSteamidporte) door.sp V= 3 -> erreur : %s", error);
                return 0;
            }
            strcopy(porteProprio3[index][0][0], 32, porteProprio4[index][0][0]);
            strcopy(pseudoProprio3[index][0][0], 32, pseudoProprio4[index][0][0]);
            strcopy(porteProprio4[index][0][0], 32, porteProprio5[index][0][0]);
            strcopy(pseudoProprio4[index][0][0], 32, pseudoProprio5[index][0][0]);
            strcopy(porteProprio5[index][0][0], 32, "Aucun");
            strcopy(pseudoProprio5[index][0][0], 32, "Aucun");
        }
        if (valeur == 4) {
            Format(rek, 512, "UPDATE Porte SET st_id3 = st_id4, pseudo3 = pseudo4, st_id4 = 'Aucun', pseudo4 = 'Aucun' WHERE id_porte = %d", index);
            if (!SQL_FastQuery(db, rek, -1)) {
                decl String:error[256];
                SQL_GetError(db, error, 255);
                Log("RolePlay Admin", "impossible de update les porte (retirSteamidporte) door.sp V= 4 -> erreur : %s", error);
                return 0;
            }
            strcopy(porteProprio4[index][0][0], 32, porteProprio5[index][0][0]);
            strcopy(pseudoProprio4[index][0][0], 32, pseudoProprio5[index][0][0]);
            strcopy(porteProprio5[index][0][0], 32, "Aucun");
            strcopy(pseudoProprio5[index][0][0], 32, "Aucun");
        }
        if (valeur == 5) {
            Format(rek, 512, "UPDATE Porte SET st_id4 = 'Aucun', pseudo4 = 'Aucun' WHERE id_porte = %d", index);
            if (!SQL_FastQuery(db, rek, -1)) {
                decl String:error[256];
                SQL_GetError(db, error, 255);
                Log("RolePlay Admin", "impossible de update les porte (retirSteamidporte) door.sp V= 5 -> erreur : %s", error);
                return 0;
            }
            strcopy(porteProprio5[index][0][0], 32, "Aucun");
            strcopy(pseudoProprio5[index][0][0], 32, "Aucun");
        }
    }
    return 0;
}

PlaceDuSteamIDPorte(index, String:steamid[32])
{
    if (StrEqual(porteProprio1[index][0][0], steamid, true)) {
        return 1;
    }
    if (StrEqual(porteProprio2[index][0][0], steamid, true)) {
        return 2;
    }
    if (StrEqual(porteProprio3[index][0][0], steamid, true)) {
        return 3;
    }
    if (StrEqual(porteProprio4[index][0][0], steamid, true)) {
        return 4;
    }
    if (StrEqual(porteProprio5[index][0][0], steamid, true)) {
        return 5;
    }
    return -1;
}

DonnerUnDoubleDesCle(client)
{
    new entity = GetClientAimTarget(client, false);
    if (entity != -1) {
        new index = porteExisteDansLaDB(entity);
        if (index != -1) {
            decl String:steamid[32];
            GetClientAuthString(client, steamid, 32);
            if (StrEqual(porteProprio1[index][0][0], steamid, true)) {
                if (ProcheJoueurPorte(entity, client)) {
                    new Handle:g_MenuDonnerCle = CreateMenu(MenuHandler:31, MenuAction:28);
                    SetMenuTitle(g_MenuDonnerCle, "Choisir … qui voulez\nvous donner\nun double des cl‚s");
                    decl String:parametre[128];
                    decl String:clientName[32];
                    decl String:steamTarget[32];
                    new i = 1;
                    while (i <= MaxClients) {
                        new var1;
                        if (IsClientInGame(i)) {
                            GetClientAuthString(i, steamTarget, 32);
                            Format(parametre, 128, "%d,%s,%d", i, steamTarget, index);
                            GetClientName(i, clientName, 32);
                            AddMenuItem(g_MenuDonnerCle, parametre, clientName, 0);
                        }
                        i++;
                    }
                    DisplayMenu(g_MenuDonnerCle, client, 300);
                } else {
                    PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Porte non enregistr‚e dans la DB !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous n'avez pas vis‚ une porte !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockDonnerCleUnJoueur(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[16][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 32);
    new clientTarget = StringToInt(split[0][split], 10);
    new index = StringToInt(split[8], 10);
    new var1;
    if (IsClientInGame(clientTarget)) {
        decl String:steamTarget[32];
        GetClientAuthString(clientTarget, steamTarget, 32);
        if (StrEqual(steamTarget, split[4], true)) {
            if (posDeuxJoueur(client, clientTarget)) {
                if (!JoueurProprio(index, steamTarget)) {
                    new place = PlacePourNewProprio(index);
                    if (place > 1) {
                        decl String:clientName[32];
                        GetClientName(clientTarget, clientName, 32);
                        ajouterNouveauProprietaire(place, index, steamTarget, clientName);
                        PrintToChat(client, "%s %s est le propri‚taire nø %d de cette porte !", "[Rp Magnetik : ->]", clientName, place);
                        PrintToChat(clientTarget, "%s Vous ‚tes propri‚taire de la porte devant vous !", "[Rp Magnetik : ->]");
                    } else {
                        PrintToChat(client, "%s Vous aviez d‚j… donn‚ tous les doubles de cl‚ (4 pers maxi) !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s La personne choisie est d‚j… propri‚taire !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s La personne choisie est trop loin de vous !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s La personne choisie est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s La personne choisie est partie !", "[Rp Magnetik : ->]");
    }
    return 0;
}

ajouterNouveauProprietaire(place, index, String:steamTarget[32], String:name[32])
{
    decl String:error[256];
    if (place == 1) {
        if (!nouvProprio1) {
            nouvProprio1 = SQL_PrepareQuery(db, "UPDATE Porte SET st_id0 = ?, pseudo0 = ? WHERE id_porte = ?", error, 255);
            if (nouvProprio1) {
            } else {
                Log("Roleplay Admin", "Impossible de preparer la requette update porte (ajouterNvPropri) door.sp P= 1 -> erreur : %s", error);
                return 0;
            }
        }
        SQL_BindParamString(nouvProprio1, 0, steamTarget, false);
        SQL_BindParamString(nouvProprio1, 1, name, false);
        SQL_BindParamInt(nouvProprio1, 2, index, false);
        if (!SQL_Execute(nouvProprio1)) {
            SQL_GetError(db, error, 255);
            Log("RolePlay Admin", "impossible de update porte (ajouterNvPropri) door.sp P= 1 -> erreur : %s", error);
            return 0;
        }
        strcopy(porteProprio1[index][0][0], 32, steamTarget);
        strcopy(pseudoProprio1[index][0][0], 32, name);
    } else {
        if (place == 2) {
            if (!nouvProprio2) {
                nouvProprio2 = SQL_PrepareQuery(db, "UPDATE Porte SET st_id1 = ?, pseudo1 = ? WHERE id_porte = ?", error, 255);
                if (nouvProprio2) {
                } else {
                    Log("Roleplay Admin", "Impossible de preparer la requette update porte (ajouterNvPropri) door.sp P= 2 -> erreur : %s", error);
                    return 0;
                }
            }
            SQL_BindParamString(nouvProprio2, 0, steamTarget, false);
            SQL_BindParamString(nouvProprio2, 1, name, false);
            SQL_BindParamInt(nouvProprio2, 2, index, false);
            if (!SQL_Execute(nouvProprio2)) {
                SQL_GetError(db, error, 255);
                Log("RolePlay Admin", "impossible de update porte (ajouterNvPropri) door.sp P= 2 -> erreur : %s", error);
                return 0;
            }
            strcopy(porteProprio2[index][0][0], 32, steamTarget);
            strcopy(pseudoProprio2[index][0][0], 32, name);
        }
        if (place == 3) {
            if (!nouvProprio3) {
                nouvProprio3 = SQL_PrepareQuery(db, "UPDATE Porte SET st_id2 = ?, pseudo2 = ? WHERE id_porte = ?", error, 255);
                if (nouvProprio3) {
                } else {
                    Log("Roleplay Admin", "Impossible de preparer la requette update porte (ajouterNvPropri) door.sp P= 3 -> erreur : %s", error);
                    return 0;
                }
            }
            SQL_BindParamString(nouvProprio3, 0, steamTarget, false);
            SQL_BindParamString(nouvProprio3, 1, name, false);
            SQL_BindParamInt(nouvProprio3, 2, index, false);
            if (!SQL_Execute(nouvProprio3)) {
                SQL_GetError(db, error, 255);
                Log("RolePlay Admin", "impossible de update porte (ajouterNvPropri) door.sp P= 3 -> erreur : %s", error);
                return 0;
            }
            strcopy(porteProprio3[index][0][0], 32, steamTarget);
            strcopy(pseudoProprio3[index][0][0], 32, name);
        }
        if (place == 4) {
            if (!nouvProprio4) {
                nouvProprio4 = SQL_PrepareQuery(db, "UPDATE Porte SET st_id3 = ?, pseudo3 = ? WHERE id_porte = ?", error, 255);
                if (nouvProprio4) {
                } else {
                    Log("Roleplay Admin", "Impossible de preparer la requette update porte (ajouterNvPropri) door.sp P= 4 -> erreur : %s", error);
                    return 0;
                }
            }
            SQL_BindParamString(nouvProprio4, 0, steamTarget, false);
            SQL_BindParamString(nouvProprio4, 1, name, false);
            SQL_BindParamInt(nouvProprio4, 2, index, false);
            if (!SQL_Execute(nouvProprio4)) {
                SQL_GetError(db, error, 255);
                Log("RolePlay Admin", "impossible de update porte (ajouterNvPropri) door.sp P= 4 -> erreur : %s", error);
                return 0;
            }
            strcopy(porteProprio4[index][0][0], 32, steamTarget);
            strcopy(pseudoProprio4[index][0][0], 32, name);
        }
        if (place == 5) {
            if (!nouvProprio5) {
                nouvProprio5 = SQL_PrepareQuery(db, "UPDATE Porte SET st_id4 = ?, pseudo4 = ? WHERE id_porte = ?", error, 255);
                if (nouvProprio5) {
                } else {
                    Log("Roleplay Admin", "Impossible de preparer la requette update porte (ajouterNvPropri) door.sp P= 5 -> erreur : %s", error);
                    return 0;
                }
            }
            SQL_BindParamString(nouvProprio5, 0, steamTarget, false);
            SQL_BindParamString(nouvProprio5, 1, name, false);
            SQL_BindParamInt(nouvProprio5, 2, index, false);
            if (!SQL_Execute(nouvProprio5)) {
                SQL_GetError(db, error, 255);
                Log("RolePlay Admin", "impossible de update porte (ajouterNvPropri) door.sp P= 5 -> erreur : %s", error);
                return 0;
            }
            strcopy(porteProprio5[index][0][0], 32, steamTarget);
            strcopy(pseudoProprio5[index][0][0], 32, name);
        }
    }
    return 0;
}

RetirerToutLesProprietaire(index)
{
    decl String:rek[512];
    Format(rek, 512, "UPDATE Porte SET st_id0 = 'Aucun', pseudo0 = 'Aucun', st_id1 = 'Aucun', pseudo1 = 'Aucun', st_id2 = 'Aucun', pseudo2 = 'Aucun', st_id3 = 'Aucun', pseudo3 = 'Aucun', st_id4 = 'Aucun', pseudo4 = 'Aucun', location = 0 WHERE id_porte = %d", index);
    if (!SQL_FastQuery(db, rek, -1)) {
        decl String:error[256];
        SQL_GetError(db, error, 255);
        Log("RolePlay Admin", "impossible de update les porte (RetirerToutLesProprietaire) door.sp -> erreur : %s", error);
        return 0;
    }
    porteLocation[index] = 0;
    strcopy(porteProprio1[index][0][0], 32, "Aucun");
    strcopy(pseudoProprio1[index][0][0], 32, "Aucun");
    strcopy(porteProprio2[index][0][0], 32, "Aucun");
    strcopy(pseudoProprio2[index][0][0], 32, "Aucun");
    strcopy(porteProprio3[index][0][0], 32, "Aucun");
    strcopy(pseudoProprio3[index][0][0], 32, "Aucun");
    strcopy(porteProprio4[index][0][0], 32, "Aucun");
    strcopy(pseudoProprio4[index][0][0], 32, "Aucun");
    strcopy(porteProprio5[index][0][0], 32, "Aucun");
    strcopy(pseudoProprio5[index][0][0], 32, "Aucun");
    return 0;
}

PlacePourNewProprio(index)
{
    if (StrEqual(porteProprio1[index][0][0], "Aucun", true)) {
        return 1;
    }
    if (StrEqual(porteProprio2[index][0][0], "Aucun", true)) {
        return 2;
    }
    if (StrEqual(porteProprio3[index][0][0], "Aucun", true)) {
        return 3;
    }
    if (StrEqual(porteProprio4[index][0][0], "Aucun", true)) {
        return 4;
    }
    if (StrEqual(porteProprio5[index][0][0], "Aucun", true)) {
        return 5;
    }
    return -1;
}

LockUnePorte(client)
{
    new entity = GetClientAimTarget(client, false);
    if (entity != -1) {
        new index = porteExisteDansLaDB(entity);
        if (index != -1) {
            decl String:steamid[32];
            GetClientAuthString(client, steamid, 32);
            new SonIdmetier = clientIdMetier[client][0][0];
            new var2;
            if (JoueurProprio(index, steamid)) {
                if (ProcheJoueurPorte(entity, client)) {
                    if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                        AcceptEntityInput(entity, "unlock", -1, -1, 0);
                        PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                    } else {
                        AcceptEntityInput(entity, "close", -1, -1, 0);
                        AcceptEntityInput(entity, "lock", -1, -1, 0);
                        PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                }
            } else {
                if (inList(index, listPorteHotelPrinc, 2)) {
                    if (ProcheJoueurPorte(entity, client)) {
                        new var3;
                        if (EstProprio(steamid, listPorteVerifHotel, 10)) {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                AcceptEntityInput(entity, "unlock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                            } else {
                                AcceptEntityInput(entity, "close", -1, -1, 0);
                                AcceptEntityInput(entity, "lock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                }
                if (inList(index, listPorteEntrerJaune, 4)) {
                    if (ProcheJoueurPorte(entity, client)) {
                        new var4;
                        if (EstProprio(steamid, listPorteVerifJaune, 4)) {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                AcceptEntityInput(entity, "unlock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                            } else {
                                AcceptEntityInput(entity, "close", -1, -1, 0);
                                AcceptEntityInput(entity, "lock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                }
                if (index == 7) {
                    if (ProcheJoueurPorte(entity, client)) {
                        new var5;
                        if (EstProprio(steamid, listePorteVerifEpic, 2)) {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                AcceptEntityInput(entity, "unlock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                            } else {
                                AcceptEntityInput(entity, "close", -1, -1, 0);
                                AcceptEntityInput(entity, "lock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                }
                if (SonIdmetier == 4) {
                    if (ProcheJoueurPorte(entity, client)) {
                        if (inList(index, listPorteComico, 31)) {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                AcceptEntityInput(entity, "unlock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                            } else {
                                AcceptEntityInput(entity, "close", -1, -1, 0);
                                AcceptEntityInput(entity, "lock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                            }
                        } else {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                PrintToChat(client, "%s Vous n'avez pas l'autorisation d'entrer !", "[Rp Magnetik : ->]");
                            }
                            AcceptEntityInput(entity, "close", -1, -1, 0);
                            AcceptEntityInput(entity, "lock", -1, -1, 0);
                            PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                }
                if (SonIdmetier == 5) {
                    if (ProcheJoueurPorte(entity, client)) {
                        if (inList(index, listPorteComiGard, 12)) {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                AcceptEntityInput(entity, "unlock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                            } else {
                                AcceptEntityInput(entity, "close", -1, -1, 0);
                                AcceptEntityInput(entity, "lock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                            }
                        } else {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                PrintToChat(client, "%s Vous n'avez pas l'autorisation d'entrer !", "[Rp Magnetik : ->]");
                            }
                            AcceptEntityInput(entity, "close", -1, -1, 0);
                            AcceptEntityInput(entity, "lock", -1, -1, 0);
                            PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                }
                if (inList(index, listAMafiaF, 2)) {
                    if (ProcheJoueurPorte(entity, client)) {
                        new var6;
                        if (SonIdmetier == 35) {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                AcceptEntityInput(entity, "unlock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                            } else {
                                AcceptEntityInput(entity, "close", -1, -1, 0);
                                AcceptEntityInput(entity, "lock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                }
                if (inList(index, listAMafiaI, 2)) {
                    if (ProcheJoueurPorte(entity, client)) {
                        new var7;
                        if (SonIdmetier == 37) {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                AcceptEntityInput(entity, "unlock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                            } else {
                                AcceptEntityInput(entity, "close", -1, -1, 0);
                                AcceptEntityInput(entity, "lock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                }
                if (inList(index, listAMafiaR, 7)) {
                    if (ProcheJoueurPorte(entity, client)) {
                        new var8;
                        if (SonIdmetier == 39) {
                            if (0 < GetEntProp(entity, PropType:1, "m_bLocked", 4)) {
                                AcceptEntityInput(entity, "unlock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est d‚verrouill‚e !", "[Rp Magnetik : ->]");
                            } else {
                                AcceptEntityInput(entity, "close", -1, -1, 0);
                                AcceptEntityInput(entity, "lock", -1, -1, 0);
                                PrintToChat(client, "%s La porte est verrouill‚e !", "[Rp Magnetik : ->]");
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                }
                PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Porte qui ne se v‚rrouille pas !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous n'avez pas vis‚ une porte !", "[Rp Magnetik : ->]");
    }
    return 0;
}

EstFlicOuGardien(client)
{
    new var1;
    if (clientIdMetier[client][0][0] == 4) {
        return 1;
    }
    return 0;
}

bool:NiveauForceSer(client, niveau)
{
    new entity = GetClientAimTarget(client, false);
    if (entity == -1) {
        PrintToChat(client, "%s Vous n'avez pas vis‚ une porte !", "[Rp Magnetik : ->]");
        return false;
    }
    new index = porteExisteDansLaDB(entity);
    if (index == -1) {
        PrintToChat(client, "%s Porte non enregistrer dans la Db !", "[Rp Magnetik : ->]");
        return false;
    }
    if (!ProcheJoueurPorte(entity, client)) {
        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
        return false;
    }
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new idmetier = clientIdMetier[client][0][0];
    new var1;
    if (JoueurProprio(index, steamid)) {
        new niv = VerifieNiveauPorte(index, niveau);
        if (niv == 3) {
            PrintToChat(client, "%s Niveau incorrecte !", "[Rp Magnetik : ->]");
            return false;
        }
        new var2;
        if (niveau == 7) {
            PrintToChat(client, "%s Porte au niveau maximum !", "[Rp Magnetik : ->]");
            return false;
        }
        new var3;
        if (niveau == 1) {
            PrintToChat(client, "%s Porte ayant une probabilit‚ inf‚rieur … 3 contacter un admin !", "[Rp Magnetik : ->]");
            return false;
        }
        if (niv == 2) {
            PrintToChat(client, "%s Il faut un niveau sup‚rieur pour renforcer cette porte !", "[Rp Magnetik : ->]");
            return false;
        }
        if (niv) {
            if (niv == 1) {
                new var4 = porteProba[index];
                var4 = var4[0][0] + 1;
                sauvegarderProbaPorte(index);
                return true;
            }
            return false;
        }
        PrintToChat(client, "%s Il faut un niveau inf‚rieur pour renforcer cette porte !", "[Rp Magnetik : ->]");
        return false;
    }
    PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
    return false;
}

sauvegarderProbaPorte(index)
{
    decl String:rek[512];
    Format(rek, 512, "UPDATE Porte SET proba = %d  WHERE id_porte = %d", porteProba[index], index);
    if (!SQL_FastQuery(db, rek, -1)) {
        decl String:error[256];
        SQL_GetError(db, error, 255);
        Log("RolePlay Admin", "impossible de update les porte (sauvegarderProbaPorte) door.sp -> erreur : %s", error);
        new var1 = porteProba[index];
        var1 = var1[0][0] + -1;
    }
    return 0;
}

DecrementProbaPorte()
{
    decl String:req[512];
    decl String:error[256];
    Format(req, 512, "UPDATE Porte SET proba = proba - 1 WHERE proba > 3 AND  id_associe = 1 OR id_associe = 2 AND proba > 3");
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de decrement les probas (DecrementProbaPorte) -> Erreur : %s", error);
        return 0;
    }
    new i = 0;
    while (i < 136) {
        new var1;
        if (porteIdAssocie[i][0][0] == 2) {
            if (porteProba[i][0][0] > 3) {
                new var2 = porteProba[i];
                var2 = var2[0][0] + -1;
                i++;
            }
            i++;
        }
        i++;
    }
    return 0;
}

VerifieNiveauPorte(index, niveau)
{
    if (niveau == 1) {
        if (porteProba[index][0][0] == 3) {
            return 1;
        }
        if (porteProba[index][0][0] > 3) {
            return 2;
        }
        return 0;
    }
    if (niveau == 2) {
        if (porteProba[index][0][0] == 4) {
            return 1;
        }
        if (porteProba[index][0][0] > 4) {
            return 2;
        }
        return 0;
    }
    if (niveau == 3) {
        if (porteProba[index][0][0] == 5) {
            return 1;
        }
        if (porteProba[index][0][0] > 5) {
            return 2;
        }
        return 0;
    }
    if (niveau == 4) {
        if (porteProba[index][0][0] == 6) {
            return 1;
        }
        if (porteProba[index][0][0] > 6) {
            return 2;
        }
        return 0;
    }
    if (niveau == 5) {
        if (porteProba[index][0][0] == 7) {
            return 1;
        }
        if (porteProba[index][0][0] > 7) {
            return 2;
        }
        return 0;
    }
    if (niveau == 6) {
        if (porteProba[index][0][0] == 8) {
            return 1;
        }
        if (porteProba[index][0][0] > 8) {
            return 2;
        }
        return 0;
    }
    if (niveau == 7) {
        if (porteProba[index][0][0] == 9) {
            return 1;
        }
        if (porteProba[index][0][0] > 9) {
            return 2;
        }
        return 0;
    }
    return 3;
}

AfficherInformationPorte(client)
{
    new entity = GetClientAimTarget(client, false);
    if (entity == -1) {
        PrintToChat(client, "%s Vous n'avez pas vis‚ une porte !", "[Rp Magnetik : ->]");
        return 0;
    }
    new index = porteExisteDansLaDB(entity);
    if (index == -1) {
        PrintToChat(client, "%s Porte non enregistrer dans la Db !", "[Rp Magnetik : ->]");
        return 0;
    }
    if (!ProcheJoueurPorte(entity, client)) {
        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
        return 0;
    }
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new idmetier = clientIdMetier[client][0][0];
    new var1;
    if (JoueurProprio(index, steamid)) {
        new Handle:g_MenuInfoPorte = CreateMenu(MenuHandler:273, MenuAction:28);
        decl String:titre[300];
        decl String:Buffer[4];
        Format(titre, 300, "| Info Porte Nø %d|\nEntit‚ : Nø %d\nNom : %s\n Temps Location : %d sec\n| Propri‚taire |\n1) %s\n2) %s\n3) %s\n4) %s\n5) %s\n Resistance serrure 1/%d", index, entity, porteNom[index][0][0], porteLocation[index], pseudoProprio1[index][0][0], pseudoProprio2[index][0][0], pseudoProprio3[index][0][0], pseudoProprio4[index][0][0], pseudoProprio5[index][0][0], porteProba[index]);
        SetMenuTitle(g_MenuInfoPorte, titre);
        Format(Buffer, 4, "9");
        AddMenuItem(g_MenuInfoPorte, Buffer, "Quitter", 0);
        DisplayMenu(g_MenuInfoPorte, client, 300);
        return 0;
    }
    PrintToChat(client, "%s Vous n'ˆtes pas propri‚taire !", "[Rp Magnetik : ->]");
    return 0;
}

public blockInfoPortePlayer(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    CancelClientMenu(client, false, Handle:0);
    return 0;
}

bool:JoueurMafiaEtPorte(index, idmetier)
{
    new var1;
    if (idmetier == 35) {
        if (inList(index, listAMafiaF, 2)) {
            return true;
        }
    } else {
        new var2;
        if (idmetier == 37) {
            if (inList(index, listAMafiaI, 2)) {
                return true;
            }
        }
        new var3;
        if (idmetier == 39) {
            if (inList(index, listAMafiaR, 7)) {
                return true;
            }
        }
    }
    return false;
}

bool:EstProprio(String:steamid[32], liste[], size)
{
    new i = 0;
    while (i < size) {
        new var1;
        if (StrEqual(porteProprio1[liste[i]][0][0], steamid, true)) {
            return true;
        }
        i++;
    }
    return false;
}

bool:ProcheJoueurPorte(entity, client)
{
    decl Float:vecPorte[3];
    decl Float:vecClient[3];
    GetEntPropVector(entity, PropType:0, "m_vecOrigin", vecPorte);
    GetClientAbsOrigin(client, vecClient);
    if (RoundToNearest(GetVectorDistance(vecPorte, vecClient, false)) < 120) {
        return true;
    }
    return false;
}

bool:JoueurProprio(index, String:steamid[32])
{
    if (StrEqual(porteProprio1[index][0][0], steamid, true)) {
        return true;
    }
    if (StrEqual(porteProprio2[index][0][0], steamid, true)) {
        return true;
    }
    if (StrEqual(porteProprio3[index][0][0], steamid, true)) {
        return true;
    }
    if (StrEqual(porteProprio4[index][0][0], steamid, true)) {
        return true;
    }
    if (StrEqual(porteProprio5[index][0][0], steamid, true)) {
        return true;
    }
    return false;
}

porteExisteDansLaDB(entity)
{
    new i = 0;
    while (i < 137) {
        if (porteNumero[i][0][0] == entity) {
            return i;
        }
        i++;
    }
    return -1;
}

CreateAdminPanel()
{
    panelAdmin = CreatePanel(Handle:0);
    SetPanelTitle(panelAdmin, "Option admin RP FReZ:", false);
    SetPanelKeys(panelAdmin, 1023);
    DrawPanelText(panelAdmin, " ");
    DrawPanelText(panelAdmin, "->1. Modifier un metier");
    DrawPanelText(panelAdmin, "->2. Modifier le level Knife");
    DrawPanelText(panelAdmin, "->3. Donner de l'argent");
    DrawPanelText(panelAdmin, "->4. Retirer de l'argent");
    DrawPanelText(panelAdmin, "->5. Menu des portes");
    DrawPanelText(panelAdmin, "->6. Information joueur");
    DrawPanelText(panelAdmin, "->7. Donner un permis 1&2");
    DrawPanelText(panelAdmin, "->8. Enlever un permis 1&2");
    DrawPanelText(panelAdmin, "->9. Demissionner un Boss");
    panelAdminlevelk = CreatePanel(Handle:0);
    SetPanelTitle(panelAdminlevelk, "Selectionner le level knife:", false);
    SetPanelKeys(panelAdminlevelk, 1023);
    DrawPanelText(panelAdminlevelk, " ");
    DrawPanelText(panelAdminlevelk, "->1. level 0");
    DrawPanelText(panelAdminlevelk, "->2. level 10");
    DrawPanelText(panelAdminlevelk, "->3. level 20");
    DrawPanelText(panelAdminlevelk, "->4. level 50");
    DrawPanelText(panelAdminlevelk, "->5. level 60");
    DrawPanelText(panelAdminlevelk, "->6. level 70");
    DrawPanelText(panelAdminlevelk, "->7. level 80");
    DrawPanelText(panelAdminlevelk, "->8. level 100");
    DrawPanelText(panelAdminlevelk, "->9. Menu Principale");
    panelAddonneArg = CreatePanel(Handle:0);
    SetPanelTitle(panelAddonneArg, "Selectionner le nombre de fric:", false);
    SetPanelKeys(panelAddonneArg, 1023);
    DrawPanelText(panelAddonneArg, " ");
    DrawPanelText(panelAddonneArg, "->1. 50 $");
    DrawPanelText(panelAddonneArg, "->2. 100 $");
    DrawPanelText(panelAddonneArg, "->3. 200 $");
    DrawPanelText(panelAddonneArg, "->4. 500 $");
    DrawPanelText(panelAddonneArg, "->5. 1000 $");
    DrawPanelText(panelAddonneArg, "->6. 2500 $");
    DrawPanelText(panelAddonneArg, "->7. 5000 $");
    DrawPanelText(panelAddonneArg, "->8. 10.000 $");
    DrawPanelText(panelAddonneArg, "->9. Menu Principale");
    panelAdPorte = CreatePanel(Handle:0);
    SetPanelTitle(panelAdPorte, "Menu des portes :", false);
    SetPanelKeys(panelAdPorte, 1023);
    DrawPanelText(panelAdPorte, " ");
    DrawPanelText(panelAdPorte, "->1. Information porte");
    DrawPanelText(panelAdPorte, "->2. Ouvrir une porte");
    DrawPanelText(panelAdPorte, "->3. Fermer un porte");
    DrawPanelText(panelAdPorte, "->4. Verouiller une porte");
    DrawPanelText(panelAdPorte, "->5. Deverouiller une porte");
    DrawPanelText(panelAdPorte, "->6. Donner les cles … un joueur");
    DrawPanelText(panelAdPorte, "->7. Enlever les cles d'un joueur");
    DrawPanelText(panelAdPorte, "->8. Menu Principale");
    panelAdPortArme = CreatePanel(Handle:0);
    SetPanelTitle(panelAdPortArme, "Menu des portes :", false);
    SetPanelKeys(panelAdPortArme, 1023);
    DrawPanelText(panelAdPortArme, " ");
    DrawPanelText(panelAdPortArme, "->1. permis port d'arme secondaire");
    DrawPanelText(panelAdPortArme, "->2. permis port d'arme primaire");
    DrawPanelText(panelAdPortArme, "->3. Menu Principale");
    return 0;
}

CreationMenuPourDonnerUnMetier()
{
    g_MenuDonnerMetier = CreateMenu(MenuHandler:19, MenuAction:28);
    SetMenuTitle(g_MenuDonnerMetier, "Modifier le metier d'un Joueur:");
    decl String:buffer[8];
    decl String:InfoObjet[60];
    new i = 1;
    while (i < 41) {
        new var1;
        if (metierChef[i][0][0]) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s", metierNom[i][0][0]);
            AddMenuItem(g_MenuDonnerMetier, buffer, InfoObjet, 0);
            i++;
        } else {
            new var2;
            if (metierChef[i][0][0] == 1) {
                Format(buffer, 8, "%d", i);
                Format(InfoObjet, 60, "%s", metierNom[i][0][0]);
                AddMenuItem(g_MenuDonnerMetier, buffer, InfoObjet, 0);
                i++;
            }
            i++;
        }
        i++;
    }
    return 0;
}

AdminRolePlayStart(client)
{
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new i = 0;
    while (i < 65) {
        if (StrEqual(steamid, ListeAdminRoleplay[i][0][0], true)) {
            OpenMenu(client, panelAdmin, MenuHandler:91);
            PrintToChat(client, "%s Bienvenue sur le panel Admin", "[Rp Magnetik : ->]");
            return 0;
        }
        i++;
    }
    return 0;
}

public BlockPanelAdmin(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (choice == 1) {
        DisplayMenu(g_MenuDonnerMetier, client, 300);
    } else {
        if (choice == 2) {
            OpenMenu(client, panelAdminlevelk, MenuHandler:85);
        }
        if (choice == 3) {
            OpenMenu(client, panelAddonneArg, MenuHandler:29);
        }
        if (choice == 4) {
            OpenMenu(client, panelAddonneArg, MenuHandler:35);
        }
        if (choice == 5) {
            OpenMenu(client, panelAdPorte, MenuHandler:93);
        }
        if (choice == 6) {
            new LeClientTarget = GetClientAimTarget(client, true);
            if (LeClientTarget != -1) {
                decl String:nameTarget[32];
                GetClientName(LeClientTarget, nameTarget, 32);
                new Handle:g_MenuInfoJoueurAdmin = CreateMenu(MenuHandler:63, MenuAction:28);
                decl String:titre[256];
                Format(titre, 256, "| Information Joueur |\nNom : %s\nPermi d'A sec : %d Permi d'A pri : %d\n Cash : %d\n Bank : %d\nMetier : %s\nPrisonnier : %d\nLevel Knife : %d/100", nameTarget, clientPermiSec[LeClientTarget], clientPermiPri[LeClientTarget], clientCash[LeClientTarget], clientBank[LeClientTarget], metierNom[clientIdMetier[LeClientTarget][0][0]][0][0], clientInJail[LeClientTarget], clientLevelKnife[LeClientTarget]);
                SetMenuTitle(g_MenuInfoJoueurAdmin, titre);
                decl String:buffer[4];
                Format(buffer, 4, "1");
                AddMenuItem(g_MenuInfoJoueurAdmin, buffer, "-> Retour", 0);
                DisplayMenu(g_MenuInfoJoueurAdmin, client, 300);
            } else {
                OpenMenu(client, panelAdmin, MenuHandler:91);
            }
        }
        if (choice == 7) {
            OpenMenu(client, panelAdPortArme, MenuHandler:33);
        }
        if (choice == 8) {
            OpenMenu(client, panelAdPortArme, MenuHandler:37);
        }
        if (choice == 9) {
        }
    }
    return 0;
}

public BlockMenuInfoPourAdmin(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new valeur = StringToInt(parametre, 10);
    if (valeur == 1) {
        OpenMenu(client, panelAdmin, MenuHandler:91);
    }
    return 0;
}

public BlockEnleverDiplome(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (choice == 1) {
        ListeplayerEDiplome(client, MenuHandler:189, "secondaire");
    } else {
        if (choice == 2) {
            ListeplayerEDiplome(client, MenuHandler:189, "primaire");
        }
        if (choice == 3) {
            OpenMenu(client, panelAdmin, MenuHandler:91);
        }
    }
    return 0;
}

ListeplayerEDiplome(client, MenuHandler:functionHandler, String:permis[12])
{
    new Handle:menu = CreateMenu(functionHandler, MenuAction:28);
    SetMenuTitle(menu, "Choisir un joueur :");
    decl String:parametre[20];
    decl String:clientName[32];
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            Format(parametre, 20, "%d,%s", GetClientUserId(i), permis);
            GetClientName(i, clientName, 32);
            AddMenuItem(menu, parametre, clientName, 0);
        }
        i++;
    }
    DisplayMenu(menu, client, 300);
    return 0;
}

public EnleverPermisPlayer(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[20];
    decl String:split[8][12];
    GetMenuItem(menu, choice, parametre, 20, 0, "", 0);
    ExplodeString(parametre, ",", split, 2, 12);
    new target = GetClientOfUserId(StringToInt(split[0][split], 10));
    decl String:clientName[64];
    GetClientName(target, clientName, 64);
    decl String:Name[32];
    GetClientName(client, Name, 32);
    new var1;
    if (target) {
        if (StrEqual(split[4], "secondaire", true)) {
            clientPermiSec[target] = 0;
            PrintToChatAll("%s Le permis de port d'arme secondaire de %s a ‚tait retir‚ par un admin Rp FReZ : %s ", 162992, clientName, Name);
        }
        if (StrEqual(split[4], "primaire", true)) {
            clientPermiPri[target] = 0;
            PrintToChatAll("%s Le permis de port d'arme Primaire de %s a ‚tait retir‚ par un admin Rp FReZ : %s", 163116, clientName, Name);
        }
    }
    return 0;
}

public BlockDonnerDiplome(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (choice == 1) {
        ListeplayerDDiplome(client, MenuHandler:183, "secondaire");
    }
    if (choice == 2) {
        ListeplayerDDiplome(client, MenuHandler:183, "primaire");
    }
    if (choice == 3) {
        OpenMenu(client, panelAdmin, MenuHandler:91);
    }
    return 0;
}

ListeplayerDDiplome(client, MenuHandler:functionHandler, String:permis[12])
{
    new Handle:menu = CreateMenu(functionHandler, MenuAction:28);
    SetMenuTitle(menu, "Choisir un joueur :");
    decl String:parametre[20];
    decl String:clientName[32];
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            Format(parametre, 20, "%d,%s", GetClientUserId(i), permis);
            GetClientName(i, clientName, 32);
            AddMenuItem(menu, parametre, clientName, 0);
        }
        i++;
    }
    DisplayMenu(menu, client, 300);
    return 0;
}

public Donnerpermisplayer(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[20];
    decl String:split[8][12];
    GetMenuItem(menu, choice, parametre, 20, 0, "", 0);
    ExplodeString(parametre, ",", split, 2, 12);
    new target = GetClientOfUserId(StringToInt(split[0][split], 10));
    new var1;
    if (target) {
        decl String:clientName[32];
        GetClientName(target, clientName, 32);
        decl String:Name[32];
        GetClientName(client, Name, 32);
        if (StrEqual(split[4], "secondaire", true)) {
            clientPermiSec[target] = 1;
            PrintToChatAll("%s Le permis de port d'arme secondaire de %s a ‚tait donn‚ par un admin Rp FReZ : %s  ", 163308, clientName, Name);
        } else {
            if (StrEqual(split[4], "primaire", true)) {
                clientPermiPri[target] = 1;
                PrintToChatAll("%s Le permis de port d'arme Primaire de %s a ‚tait donn‚ par un admin Rp FReZ : %s ", 163432, clientName, Name);
            }
        }
    }
    return 0;
}

public BlockModifierLevelKnife(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (choice == 1) {
        ListeJoueurMKnife(client, MenuHandler:223, 0);
    } else {
        if (choice == 2) {
            ListeJoueurMKnife(client, MenuHandler:223, 10);
        }
        if (choice == 3) {
            ListeJoueurMKnife(client, MenuHandler:223, 20);
        }
        if (choice == 4) {
            ListeJoueurMKnife(client, MenuHandler:223, 50);
        }
        if (choice == 5) {
            ListeJoueurMKnife(client, MenuHandler:223, 60);
        }
        if (choice == 6) {
            ListeJoueurMKnife(client, MenuHandler:223, 70);
        }
        if (choice == 7) {
            ListeJoueurMKnife(client, MenuHandler:223, 80);
        }
        if (choice == 8) {
            ListeJoueurMKnife(client, MenuHandler:223, 100);
        }
        if (choice == 9) {
            OpenMenu(client, panelAdmin, MenuHandler:91);
        }
    }
    return 0;
}

ListeJoueurMKnife(client, MenuHandler:functionHandler, knife)
{
    new Handle:menu = CreateMenu(functionHandler, MenuAction:28);
    SetMenuTitle(menu, "Choisir un joueur :");
    decl String:parametre[16];
    decl String:clientName[32];
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            Format(parametre, 16, "%d,%d", GetClientUserId(i), knife);
            GetClientName(i, clientName, 32);
            AddMenuItem(menu, parametre, clientName, 0);
        }
        i++;
    }
    DisplayMenu(menu, client, 300);
    return 0;
}

public ModifierKnifeJoueur(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[8][8];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 2, 8);
    new target = GetClientOfUserId(StringToInt(split[0][split], 10));
    new knife = StringToInt(split[4], 10);
    new var1;
    if (target) {
        decl String:clientName[32];
        GetClientName(target, clientName, 32);
        clientLevelKnife[target] = knife;
        decl String:Name[32];
        GetClientName(client, Name, 32);
        PrintToChatAll("%s Le level knife de %s est de %d/100 modifi‚ par un admin Rp FReZ : %s ", 163572, clientName, knife, Name);
    }
    return 0;
}

public BlockDonnerArgent(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (choice == 1) {
        ListeJoueurDArgent(client, MenuHandler:181, 50);
    } else {
        if (choice == 2) {
            ListeJoueurDArgent(client, MenuHandler:181, 100);
        }
        if (choice == 3) {
            ListeJoueurDArgent(client, MenuHandler:181, 200);
        }
        if (choice == 4) {
            ListeJoueurDArgent(client, MenuHandler:181, 500);
        }
        if (choice == 5) {
            ListeJoueurDArgent(client, MenuHandler:181, 1000);
        }
        if (choice == 6) {
            ListeJoueurDArgent(client, MenuHandler:181, 2500);
        }
        if (choice == 7) {
            ListeJoueurDArgent(client, MenuHandler:181, 5000);
        }
        if (choice == 8) {
            ListeJoueurDArgent(client, MenuHandler:181, 10000);
        }
        if (choice == 9) {
            OpenMenu(client, panelAdmin, MenuHandler:91);
        }
    }
    return 0;
}

ListeJoueurDArgent(client, MenuHandler:functionHandler, argent)
{
    new Handle:menu = CreateMenu(functionHandler, MenuAction:28);
    SetMenuTitle(menu, "Choisir un joueur :");
    decl String:parametre[16];
    decl String:clientName[32];
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            Format(parametre, 16, "%d,%d", GetClientUserId(i), argent);
            GetClientName(i, clientName, 32);
            AddMenuItem(menu, parametre, clientName, 0);
        }
        i++;
    }
    DisplayMenu(menu, client, 300);
    return 0;
}

public DonnerArgentClient(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[8][8];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 2, 8);
    new target = GetClientOfUserId(StringToInt(split[0][split], 10));
    new argent = StringToInt(split[4], 10);
    new var1;
    if (target) {
        decl String:clientName[32];
        GetClientName(target, clientName, 32);
        new var2 = clientCash[target];
        var2 = var2[0][0] + argent;
        decl String:Name[32];
        GetClientName(client, Name, 32);
        PrintToChatAll("%s Le compte de %s a ‚tait modifi‚ de %d $ par un admin Rp FReZ : %s ", 163708, clientName, argent, Name);
    }
    return 0;
}

public BlockEnleverArgent(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (choice == 1) {
        ListeJoueurDArgent(client, MenuHandler:181, -50);
    } else {
        if (choice == 2) {
            ListeJoueurDArgent(client, MenuHandler:181, -100);
        }
        if (choice == 3) {
            ListeJoueurDArgent(client, MenuHandler:181, -200);
        }
        if (choice == 4) {
            ListeJoueurDArgent(client, MenuHandler:181, -500);
        }
        if (choice == 5) {
            ListeJoueurDArgent(client, MenuHandler:181, -1000);
        }
        if (choice == 6) {
            ListeJoueurDArgent(client, MenuHandler:181, -2500);
        }
        if (choice == 7) {
            ListeJoueurDArgent(client, MenuHandler:181, -5000);
        }
        if (choice == 8) {
            ListeJoueurDArgent(client, MenuHandler:181, -10000);
        }
        if (choice == 9) {
            OpenMenu(client, panelAdmin, MenuHandler:91);
        }
    }
    return 0;
}

public BlockChangerDeMetier(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new idMetier = StringToInt(parametre, 10);
    new Handle:g_menuJoueur = CreateMenu(MenuHandler:21, MenuAction:28);
    SetMenuTitle(g_menuJoueur, "Choisir un joueur :");
    decl String:para[16];
    decl String:clientName[32];
    new i = 1;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            Format(para, 16, "%d,%d", GetClientUserId(i), idMetier);
            GetClientName(i, clientName, 32);
            AddMenuItem(g_menuJoueur, para, clientName, 0);
        }
        i++;
    }
    DisplayMenu(g_menuJoueur, client, 300);
    return 0;
}

bool:inList(num, liste[], size)
{
    new i = 0;
    while (i < size) {
        if (liste[i] == num) {
            return true;
        }
        i++;
    }
    return false;
}

public BlockChoixChangerMetier(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[8][8];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 2, 8);
    new target = GetClientOfUserId(StringToInt(split[0][split], 10));
    new idmetier = StringToInt(split[4], 10);
    decl String:clientName[32];
    GetClientName(target, clientName, 32);
    new var1;
    if (target) {
        new SonIdMetier = clientIdMetier[target][0][0];
        if (SonIdMetier == 1) {
            if (inList(idmetier, listMetiersSpe, 5)) {
                DonnerMetierSpecial(target, idmetier);
            } else {
                if (inList(idmetier, listMetierChef, 17)) {
                    DonnerMetierBoss(target, idmetier);
                }
            }
        } else {
            if (inList(SonIdMetier, listMetiersSpe, 5)) {
                DemissionerMetierSpecial(target);
            } else {
                if (inList(SonIdMetier, listMetierChef, 17)) {
                    DemissionerMetierBoss(target);
                }
                if (inList(SonIdMetier, listMetierSimple, 18)) {
                    DemissionerMetierSimple(target);
                }
            }
            if (idmetier != 1) {
                if (inList(idmetier, listMetiersSpe, 5)) {
                    DonnerMetierSpecial(target, idmetier);
                }
                if (inList(idmetier, listMetierChef, 17)) {
                    DonnerMetierBoss(target, idmetier);
                }
            }
        }
        decl String:Name[32];
        GetClientName(client, Name, 32);
        PrintToChatAll("%s %s est devenu %s par un Admin Rp : %s ", 163816, clientName, metierNom[idmetier][0][0], Name);
    }
    return 0;
}

public BlockPorteMenu(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (choice == 1) {
        InFormationPorte(client);
    } else {
        if (choice == 2) {
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                AcceptEntityInput(entity, "open", -1, -1, 0);
            }
            OpenMenu(client, panelAdPorte, MenuHandler:93);
        }
        if (choice == 3) {
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                AcceptEntityInput(entity, "close", -1, -1, 0);
            }
            OpenMenu(client, panelAdPorte, MenuHandler:93);
        }
        if (choice == 4) {
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                AcceptEntityInput(entity, "lock", -1, -1, 0);
            }
            OpenMenu(client, panelAdPorte, MenuHandler:93);
        }
        if (choice == 5) {
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                AcceptEntityInput(entity, "close", -1, -1, 0);
                AcceptEntityInput(entity, "unlock", -1, -1, 0);
            }
            OpenMenu(client, panelAdPorte, MenuHandler:93);
        }
        if (choice == 6) {
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                new index = porteExisteDansLaDB(entity);
                if (index != -1) {
                    new Handle:g_MenuDonCle = CreateMenu(MenuHandler:27, MenuAction:28);
                    SetMenuTitle(g_MenuDonCle, "Choisir … qui voulez\nvous donner\nun double des cl‚s");
                    decl String:parametre[128];
                    decl String:clientName[32];
                    decl String:steamTarget[32];
                    new i = 1;
                    while (i <= MaxClients) {
                        new var2;
                        if (IsClientInGame(i)) {
                            GetClientAuthString(i, steamTarget, 32);
                            Format(parametre, 128, "%d,%s,%d", i, steamTarget, index);
                            GetClientName(i, clientName, 32);
                            AddMenuItem(g_MenuDonCle, parametre, clientName, 0);
                        }
                        i++;
                    }
                    DisplayMenu(g_MenuDonCle, client, 300);
                } else {
                    PrintToChat(client, "%s Porte non enregistrer dans la DB !", "[Rp Magnetik : ->]");
                    OpenMenu(client, panelAdPorte, MenuHandler:93);
                }
            } else {
                OpenMenu(client, panelAdPorte, MenuHandler:93);
            }
        }
        if (choice == 7) {
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                new index = porteExisteDansLaDB(entity);
                if (index != -1) {
                    new Handle:g_MenuEnleveCle = CreateMenu(MenuHandler:101, MenuAction:28);
                    SetMenuTitle(g_MenuEnleveCle, "Choisir … qui voulez\nvous retirer\nun double des cl‚s");
                    decl String:buffer[32];
                    decl String:parametre[64];
                    if (!StrEqual(porteProprio1[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio1[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio1[index][0][0]);
                        AddMenuItem(g_MenuEnleveCle, parametre, buffer, 0);
                    }
                    if (!StrEqual(porteProprio2[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio2[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio2[index][0][0]);
                        AddMenuItem(g_MenuEnleveCle, parametre, buffer, 0);
                    }
                    if (!StrEqual(porteProprio3[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio3[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio3[index][0][0]);
                        AddMenuItem(g_MenuEnleveCle, parametre, buffer, 0);
                    }
                    if (!StrEqual(porteProprio4[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio4[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio4[index][0][0]);
                        AddMenuItem(g_MenuEnleveCle, parametre, buffer, 0);
                    }
                    if (!StrEqual(porteProprio5[index][0][0], "Aucun", true)) {
                        Format(parametre, 64, "%s,%d", porteProprio5[index][0][0], index);
                        strcopy(buffer, 32, pseudoProprio5[index][0][0]);
                        AddMenuItem(g_MenuEnleveCle, parametre, buffer, 0);
                    }
                    if (!DisplayMenu(g_MenuEnleveCle, client, 300)) {
                        PrintToChat(client, "%s Aucun double de cl‚s a ‚tait donn‚ !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Porte non enregistrer dans la DB !", "[Rp Magnetik : ->]");
                    OpenMenu(client, panelAdPorte, MenuHandler:93);
                }
            } else {
                OpenMenu(client, panelAdPorte, MenuHandler:93);
            }
        }
        if (choice == 8) {
            OpenMenu(client, panelAdmin, MenuHandler:91);
        }
    }
    return 0;
}

public BlockDonCleUnJoueur(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[16][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 32);
    new clientTarget = StringToInt(split[0][split], 10);
    new index = StringToInt(split[8], 10);
    new var1;
    if (IsClientInGame(clientTarget)) {
        decl String:steamTarget[32];
        GetClientAuthString(clientTarget, steamTarget, 32);
        if (StrEqual(steamTarget, split[4], true)) {
            if (!JoueurProprio(index, steamTarget)) {
                new place = PlacePourNewProprio(index);
                if (0 < place) {
                    decl String:clientName[32];
                    GetClientName(clientTarget, clientName, 32);
                    ajouterNouveauProprietaire(place, index, steamTarget, clientName);
                    PrintToChat(client, "%s %s est le propri‚taire nø %d de cette porte !", "[Rp Magnetik : ->]", clientName, place);
                    PrintToChat(clientTarget, "%s Vous ‚tes propri‚taire de la porte : %s!", "[Rp Magnetik : ->]", porteNom[index][0][0]);
                } else {
                    PrintToChat(client, "%s Il y a plus de place pour rajouter un propri‚taire !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s La personne choisie est d‚j… propri‚taire !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s La personne choisie est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s La personne choisie est partie !", "[Rp Magnetik : ->]");
    }
    return 0;
}

InFormationPorte(client)
{
    new entity = GetClientAimTarget(client, false);
    if (entity != -1) {
        new index = porteExisteDansLaDB(entity);
        if (index != -1) {
            new Handle:g_MenuInfoPorte = CreateMenu(MenuHandler:271, MenuAction:28);
            decl String:titre[300];
            decl String:Buffer[4];
            Format(titre, 300, "| Info Porte Nø %d|\nEntit‚ : Nø %d\nNom : %s\nPrix: %d $ / jour\n Temps Louer : %d sec\n| Propri‚taire |\n1) %s\n2) %s\n3) %s\n4) %s\n5) %s\n Proba 1/%d", index, entity, porteNom[index][0][0], portePrix[index], porteLocation[index], pseudoProprio1[index][0][0], pseudoProprio2[index][0][0], pseudoProprio3[index][0][0], pseudoProprio4[index][0][0], pseudoProprio5[index][0][0], porteProba[index]);
            SetMenuTitle(g_MenuInfoPorte, titre);
            Format(Buffer, 4, "9");
            AddMenuItem(g_MenuInfoPorte, Buffer, "retour Menu", 0);
            DisplayMenu(g_MenuInfoPorte, client, 300);
        } else {
            PrintToChat(client, "%s Porte non enregistrer dans la DB !", "[Rp Magnetik : ->]");
        }
    } else {
        OpenMenu(client, panelAdPorte, MenuHandler:93);
    }
    return 0;
}

public blockInfoPorte(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (num == 9) {
        OpenMenu(client, panelAdPorte, MenuHandler:93);
    }
    return 0;
}

DemissionerMetierSpecial(client)
{
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new var1;
    if (client) {
        CS_SwitchTeam(client, 2);
        clientTeam[client] = 2;
        clientIdMetier[client] = 1;
        clientLevelKnife[client] = 0;
        clientPrecision[client] = 0;
        clientPermiPri[client] = 0;
        clientPermiSec[client] = 0;
        strcopy(clientSkin[client][0][0], 32, "t_leet");
        if (db) {
            decl String:error[256];
            decl String:sql[256];
            Format(sql, 256, "UPDATE Player SET team = 2, id_metier = 1, skins = 't_leet'  WHERE steamid='%s'", steamid);
            if (!SQL_FastQuery(db, sql, -1)) {
                SQL_GetError(db, error, 256);
                Log("Roleplay FReZ", "Impossible de demissioner special (table player, error: %s)", error);
            }
        }
        Log("Roleplay FReZ", "Impossible de se connecter a la DB");
        return 0;
    } else {
        Log("Roleplay FReZ", "Impossible de faire d‚missioner une personne car client = 0 ou pas dans le jeu");
    }
    return 0;
}

DemissionerMetierBoss(client)
{
    new var1;
    if (client) {
        decl String:bossSteamId[32];
        GetClientAuthString(client, bossSteamId, 32);
        new SonIdMetier = clientIdMetier[client][0][0];
        if (inList(SonIdMetier, listMetierChef, 17)) {
            decl String:sql[400];
            decl String:error[256];
            if (!demissionUser) {
                demissionUser = SQL_PrepareQuery(db, "SELECT st_job1, st_job2, st_job3, st_job4 FROM Bossjob WHERE st_job0 = ?", error, 256);
                if (demissionUser) {
                } else {
                    Log("RolePlay Admin", "Impossible de preparer la requette de (DemissionerMetierBoss()) ->erreur : %s", error);
                    return 0;
                }
            }
            SQL_BindParamString(demissionUser, 0, bossSteamId, false);
            if (!SQL_Execute(demissionUser)) {
                Log("Roleplay FReZ", "Impossible de select les salarie boss non enregistrer dans la db (demissionerMetierBoss)");
                return 0;
            }
            if (SQL_FetchRow(demissionUser)) {
                decl String:steamid[32];
                new i = 0;
                while (i < 4) {
                    SQL_FetchString(demissionUser, i, steamid, 32, 0);
                    if (!StrEqual(steamid, "Aucun", true)) {
                        mettre_a_jour_joueur(steamid);
                        Format(sql, 400, "UPDATE Player SET team = 2, id_metier = 1, skins = 't_leet', vente_moi = 0, vente_annee = 0, salaire_sup = 0 WHERE steamid = '%s'", steamid);
                        if (!SQL_FastQuery(db, sql, -1)) {
                            SQL_GetError(db, error, 256);
                            Log("RolePlay Admin", "Impossible de mettre un joueur sans emploi (DemissionerMetierBoss()) ->erreur : %s", error);
                            return 0;
                        }
                    }
                    i++;
                }
                clientTeam[client] = 2;
                clientIdMetier[client] = 1;
                strcopy(clientSkin[client][0][0], 32, "t_leet");
                Format(sql, 400, "UPDATE Player SET team = 2, id_metier = 1, skins = 't_leet', vente_moi = 0, vente_annee = 0, salaire_sup = 0 WHERE steamid = '%s'", bossSteamId);
                if (!SQL_FastQuery(db, sql, -1)) {
                    SQL_GetError(db, error, 256);
                    Log("RolePlay Admin", "Impossible de mettre par default les info du boss dans player (DemissionerMetierBoss())-> %s ", error);
                    return 0;
                }
                if (!deleteUser) {
                    deleteUser = SQL_PrepareQuery(db, "DELETE FROM Bossjob WHERE Bossjob.st_job0 = ? ", error, 256);
                    if (deleteUser) {
                    } else {
                        Log("RolePlay Admin", "Impossible de preparer la requette pour delete le boss (DemissionerMetierBoss()) ->erreur : %s", error);
                        return 0;
                    }
                }
                SQL_BindParamString(deleteUser, 0, bossSteamId, false);
                if (!SQL_Execute(deleteUser)) {
                    Log("Roleplay FReZ", "Impossible de delete boss dans jobBoss (demissionerMetierBoss)");
                    return 0;
                }
            }
            Log("RolePlay Admin", "Impossible de faire demissionner les salalier du boss !");
            return 0;
        }
    }
    return 0;
}

mettre_a_jour_joueur(String:steamid[])
{
    decl String:clientSteamId[32];
    new client = 1;
    while (client <= MaxClients) {
        new var1;
        if (IsClientInGame(client)) {
            GetClientAuthString(client, clientSteamId, 32);
            if (StrEqual(clientSteamId, steamid, true)) {
                clientTeam[client] = 2;
                clientIdMetier[client] = 1;
                strcopy(clientSkin[client][0][0], 32, "t_leet");
                PrintToChat(client, "%s Vous ˆtes licencier (sans emploi) !", "[Rp Magnetik : ->]");
                client++;
            }
            client++;
        }
        client++;
    }
    return 0;
}

DemissionerMetierSimple(client)
{
    new SonIdMetier = clientIdMetier[client][0][0];
    if (inList(SonIdMetier, listMetierSimple, 18)) {
        decl String:steamid[32];
        GetClientAuthString(client, steamid, 32);
        decl String:error[256];
        if (!demissionSimple) {
            demissionSimple = SQL_PrepareQuery(db, "SELECT st_job0, st_job1, st_job2, st_job3, st_job4 FROM Bossjob WHERE st_job1 = ? OR st_job2 = ? OR st_job3 = ? OR st_job4 = ?", error, 256);
            if (demissionSimple) {
            } else {
                Log("RolePlay Admin", "Impossible de preparer la requette de (DemissionerMetierSimple()) ->erreur : %s", error);
                return 0;
            }
        }
        SQL_BindParamString(demissionSimple, 0, steamid, false);
        SQL_BindParamString(demissionSimple, 1, steamid, false);
        SQL_BindParamString(demissionSimple, 2, steamid, false);
        SQL_BindParamString(demissionSimple, 3, steamid, false);
        if (!SQL_Execute(demissionSimple)) {
            Log("Roleplay FReZ", "Impossible de select tous les steam id (DemissionerMetierSimple)");
            return 0;
        }
        decl String:steamBoss[32];
        decl String:steamId1[32];
        decl String:steamId2[32];
        decl String:steamId3[32];
        decl String:steamId4[32];
        if (SQL_FetchRow(demissionSimple)) {
            SQL_FetchString(demissionSimple, 0, steamBoss, 32, 0);
            SQL_FetchString(demissionSimple, 1, steamId1, 32, 0);
            SQL_FetchString(demissionSimple, 2, steamId2, 32, 0);
            SQL_FetchString(demissionSimple, 3, steamId3, 32, 0);
            SQL_FetchString(demissionSimple, 4, steamId4, 32, 0);
            new position = -1;
            if (StrEqual(steamid, steamId1, true)) {
                position = 1;
            } else {
                if (StrEqual(steamid, steamId2, true)) {
                    position = 2;
                }
                if (StrEqual(steamid, steamId3, true)) {
                    position = 3;
                }
                if (StrEqual(steamid, steamId4, true)) {
                    position = 4;
                }
            }
            if (0 > position) {
                Log("Roleplay FReZ", "position incorete du joueur dans joboss !");
                return 0;
            }
            decl String:sql[256];
            Format(sql, 256, "UPDATE Player SET id_metier = 1, team = 2, skins = 't_leet', vente_moi = 0, vente_annee = 0, salaire_sup = 0 WHERE steamid = '%s'", steamid);
            if (!SQL_FastQuery(db, sql, -1)) {
                SQL_GetError(db, error, 256);
                Log("Roleplay FReZ", "Impossible de mettre par defaut un player en demissionnant metier simple -> Erreur : %s", error);
                return 0;
            }
            clientTeam[client] = 2;
            clientIdMetier[client] = 1;
            strcopy(clientSkin[client][0][0], 32, "t_leet");
            if (position != -1) {
                if (!remettre_danslordre_jobboss(steamBoss, position)) {
                    Log("Roleplay Admin", "Impossible de decaler les joueur dans jobboss (remettre dans l'ordre)(DemissionerMetierSimple)");
                    return 0;
                }
            }
        }
        Log("Roleplay FReZ", "Impossible de select st_job 0 dans (DemissionerMetierSimple)");
        return 0;
    }
    return 0;
}

bool:remettre_danslordre_jobboss(String:steamBoss[], position)
{
    new var1 = position;
    if (!var1 <= 4 & 1 <= var1) {
        Log("Roleplay FReZ", "Erreur de position pour remettre dans l'odre job boss :");
        return false;
    }
    decl String:sql[512];
    decl String:error[256];
    if (position == 1) {
        Format(sql, 512, "UPDATE Bossjob SET st_job1 = st_job2, st_job2 = st_job3, st_job3 = st_job4, st_job4 = 'Aucun' WHERE st_job0 = '%s'", steamBoss);
    } else {
        if (position == 2) {
            Format(sql, 512, "UPDATE Bossjob SET st_job2 = st_job3, st_job3 = st_job4, st_job4 = 'Aucun' WHERE st_job0 = '%s'", steamBoss);
        }
        if (position == 3) {
            Format(sql, 512, "UPDATE Bossjob SET st_job3 = st_job4, st_job4 = 'Aucun' WHERE st_job0 = '%s'", steamBoss);
        }
        if (position == 4) {
            Format(sql, 512, "UPDATE Bossjob SET st_job4 = 'Aucun' WHERE st_job0 = '%s'", steamBoss);
        }
    }
    if (!SQL_FastQuery(db, sql, -1)) {
        SQL_GetError(db, error, 256);
        Log("Roleplay FReZ", "Impossible de remettre dans l'ordre la db de jobboss -> Erreur : %s", error);
        return false;
    }
    return true;
}

DonnerMetierBoss(client, idmetier)
{
    if (inList(idmetier, listMetierChef, 17)) {
        new SonIdMetier = clientIdMetier[client][0][0];
        if (SonIdMetier == 1) {
            decl String:error[256];
            if (!updateBoss) {
                updateBoss = SQL_PrepareQuery(db, "INSERT INTO Bossjob (st_job0, id_metier) VALUES (?,?)", error, 255);
                if (updateBoss) {
                } else {
                    Log("Roleplay FReZ", "Impossible d'inserer un Chef de metier dans la table bossjob (error: %s)", error);
                    return 0;
                }
            }
            decl String:steamid[32];
            GetClientAuthString(client, steamid, 32);
            SQL_BindParamString(updateBoss, 0, steamid, false);
            SQL_BindParamInt(updateBoss, 1, idmetier, false);
            decl String:sql[512];
            if (!SQL_Execute(updateBoss)) {
                Log("Roleplay FReZ", "Un Chef de metier est deja enregistrer dans la table bossjob (donnerMetierBoss)");
                Format(sql, 512, "UPDATE Bossjob SET st_job1 = 'Aucun', st_job2 = 'Aucun', st_job3 = 'Aucun', st_job4 = 'Aucun', id_metier = %d, capital_groupe = 0, vente_npc_moi = 0, vente_npc_annee = 0 WHERE st_job0 = '%s'", idmetier, steamid);
                if (!SQL_FastQuery(db, sql, -1)) {
                    SQL_GetError(db, error, 255);
                    Log("Roleplay FReZ", "Impossible de modifier tous les salaries de jobboss DemissionerMetierBoss() -> Erreur : %s", error);
                    return 0;
                }
            }
            clientIdMetier[client] = idmetier;
            Format(sql, 512, "UPDATE Player SET id_metier = '%d' WHERE steamid='%s'", idmetier, steamid);
            if (!SQL_FastQuery(db, sql, -1)) {
                decl String:erreur[256];
                SQL_GetError(db, erreur, 256);
                Log("Roleplay FReZ", "Impossible de modifier le id metier pour metier boss (donneMetierBoss) -> erreur : %s", erreur);
                clientIdMetier[client] = 1;
                return 0;
            }
        } else {
            PrintToChat(client, "%s Tu n'es pas sans emploi ! ", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

DonnerMetierSimple(client, idmetier, String:steamboss[])
{
    if (inList(idmetier, listMetierSimple, 18)) {
        new sonidmetier = clientIdMetier[client][0][0];
        if (sonidmetier == 1) {
            decl String:sql[256];
            decl String:error[256];
            decl String:steamid[32];
            GetClientAuthString(client, steamid, 32);
            new emplacement = Verification_place_salarie(steamboss);
            if (emplacement == -1) {
                return 0;
            }
            if (emplacement) {
                Format(sql, 256, "UPDATE Bossjob SET st_job%d = '%s' WHERE st_job0= '%s'", emplacement, steamid, steamboss);
                if (!SQL_FastQuery(db, sql, -1)) {
                    SQL_GetError(db, error, 256);
                    Log("Roleplay FReZ", "Impossible de update le steamid dans bossjob pour recruter metier simple ! ->erreur: %s", error);
                    return 0;
                }
                Format(sql, 256, "UPDATE Player SET id_metier = %d WHERE steamid = '%s' ", idmetier, steamid);
                if (!SQL_FastQuery(db, sql, -1)) {
                    SQL_GetError(db, error, 256);
                    Log("Roleplay FReZ", "Impossible de update le idmetier dans player pour recruter metier simple ! ->erreur: %s", error);
                    return 0;
                }
                clientIdMetier[client] = idmetier;
                PrintToChat(client, "%s F‚licitation vous ‚tŠs devenu %s ! ", "[Rp Magnetik : ->]", metierNom[idmetier][0][0]);
            }
            PrintToChat(client, "%s Vous ne pouvez pas ˆtre recrut‚ car l'employeur … d‚ja 4 salari‚s ! ", "[Rp Magnetik : ->]");
            return 0;
        } else {
            PrintToChat(client, "%s Tu n'es pas sans emploi ! ", "[Rp Magnetik : ->]");
        }
    } else {
        Log("RolePlay Admin", "idmetier pour donner un metier simple est incorrecte");
    }
    return 0;
}

Verification_place_salarie(String:steamid[])
{
    decl String:error[256];
    if (!selectSalarie) {
        selectSalarie = SQL_PrepareQuery(db, "SELECT st_job1, st_job2, st_job3, st_job4 FROM Bossjob WHERE st_job0 = ?", error, 256);
        if (selectSalarie) {
        } else {
            Log("Roleplay FReZ", "Il y a une erreur dans la preparation de la requete pour verication place salarie (error: %s)", error);
            return -1;
        }
    }
    SQL_BindParamString(selectSalarie, 0, steamid, false);
    if (!SQL_Execute(selectSalarie)) {
        Log("Roleplay FReZ", "Impossible de select les salarie boss non enregistrer dans la db");
        return -1;
    }
    decl String:SteamidSalarie[32];
    if (SQL_FetchRow(selectSalarie)) {
        new i = 0;
        while (i < 4) {
            SQL_FetchString(selectSalarie, i, SteamidSalarie, 32, 0);
            if (StrEqual(SteamidSalarie, "Aucun", true)) {
                return i + 1;
            }
            i++;
        }
    }
    return 0;
}

DonnerMetierSpecial(client, idmetier)
{
    if (inList(idmetier, listMetiersSpe, 5)) {
        new SonIdMetier = clientIdMetier[client][0][0];
        if (SonIdMetier == 1) {
            decl String:sql[256];
            decl String:error[256];
            decl String:steamid[32];
            GetClientAuthString(client, steamid, 32);
            new var1;
            if (idmetier == 4) {
                clientTeam[client] = 3;
                clientLevelKnife[client] = 100;
                clientPrecision[client] = 100;
                clientPermiPri[client] = 1;
                clientPermiSec[client] = 1;
                strcopy(clientSkin[client][0][0], 32, "police");
                Format(sql, 256, "UPDATE Player SET team = 3, skins = 'police' WHERE steamid='%s'", steamid);
                if (!SQL_FastQuery(db, sql, -1)) {
                    SQL_GetError(db, error, 256);
                    Log("Roleplay FReZ", "Impossible de donner le metier de policier (special) ->erreur : %s", error);
                    PrintToChatAll("%s Impossible de donner le metier de policier (special) ! ", 169636);
                    clientIdMetier[client] = 1;
                    clientTeam[client] = 2;
                    strcopy(clientSkin[client][0][0], 32, "t_leet");
                    return 0;
                }
                ChangerEquipe(client, 3);
                DonnerUnSkinJoueur(client);
                SetEntityHealth(client, 500);
            } else {
                if (idmetier == 2) {
                    clientLevelKnife[client] = 100;
                    clientPrecision[client] = 100;
                    clientPermiPri[client] = 1;
                    clientPermiSec[client] = 1;
                    clientTeam[client] = 3;
                    Format(sql, 256, "UPDATE Player SET team = 3 WHERE steamid='%s'", steamid);
                    if (!SQL_FastQuery(db, sql, -1)) {
                        SQL_GetError(db, error, 256);
                        Log("Roleplay FReZ", "Impossible de donner le metier de chef d'etat (special) ->erreur : %s", error);
                        PrintToChatAll("%s Impossible de donner le metier de chef d'etat (special) ! ", 169868);
                        clientIdMetier[client] = 1;
                        clientTeam[client] = 2;
                        return 0;
                    }
                    strcopy(clientSkin[client][0][0], 32, "civilians");
                    ChangerEquipe(client, 3);
                    DonnerUnSkinJoueur(client);
                    SetEntityHealth(client, 1000);
                }
                if (idmetier == 3) {
                    clientLevelKnife[client] = 100;
                    clientPrecision[client] = 100;
                    clientPermiPri[client] = 1;
                    clientPermiSec[client] = 1;
                }
            }
            clientIdMetier[client] = idmetier;
            Format(sql, 256, "UPDATE Player SET id_metier = %d WHERE steamid='%s'", idmetier, steamid);
            if (!SQL_FastQuery(db, sql, -1)) {
                SQL_GetError(db, error, 256);
                Log("Roleplay FReZ", "Impossible de changer l'idmetier sur la db d'un joueur ->erreur : %s", error);
                PrintToChatAll("%s Impossible de changer l'idmetier sur la db d'un joueur ! ", 170108);
                clientIdMetier[client] = 1;
                clientTeam[client] = 2;
                strcopy(clientSkin[client][0][0], 32, "t_leet");
                return 0;
            }
            return 0;
        } else {
            PrintToChat(client, "%s Tu n'es pas sans emploi ! ", "[Rp Magnetik : ->]");
            return 0;
        }
        return 0;
    }
    PrintToChat(client, "%s  tu est deja dans la liste de job! ", "[Rp Magnetik : ->]");
    Log("RolePlay FReZ", "joueur deja enregistrer en t'en que boss ^^");
    return 0;
}

RecrutementUnJoueur(client)
{
    if (inList(clientIdMetier[client][0][0], listMetierChef, 17)) {
        if (viseJoueur(client)) {
            if (clientIdMetier[client][0][0] == 6) {
                OpenMenu(client, panelhopital, MenuHandler:1);
            } else {
                PrintToChat(client, "%s Veuillez patienter pendant que le joueur Accepte ou refuse sont recrutement !", "[Rp Magnetik : ->]");
                g_RecrutementMetierSimple = CreateMenu(MenuHandler:25, MenuAction:28);
                decl String:titre[128];
                decl String:buffer[128];
                new idmetier = clientIdMetier[client][0][0] + 1;
                decl String:steamboss[32];
                GetClientAuthString(client, steamboss, 32);
                Format(titre, 128, "Validation de recrutement :\nVoulez vous etres : %s", metierNom[clientIdMetier[client][0][0] + 1][0][0]);
                SetMenuTitle(g_RecrutementMetierSimple, titre);
                Format(buffer, 128, "1,%s,%d,%d", steamboss, idmetier, client);
                AddMenuItem(g_RecrutementMetierSimple, buffer, "-> Accepter", 0);
                Format(buffer, 128, "2,%s,%d,%d", steamboss, idmetier, client);
                AddMenuItem(g_RecrutementMetierSimple, buffer, "-> Refuser", 0);
                DisplayMenu(g_RecrutementMetierSimple, GetClientAimTarget(client, true), 300);
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas vis‚ quelqu'un ou vous ‚tes trop loin !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Tu ne peux pas recrute, car tu n'es pas chef !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockConfirmationRecrutement(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[16][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 32);
    new valeur = StringToInt(split[0][split], 10);
    new idmetier = StringToInt(split[8], 10);
    new clientBoss = StringToInt(split[12], 10);
    new var1;
    if (valeur == 1) {
        DonnerMetierSimple(client, idmetier, split[4]);
    } else {
        new var2;
        if (IsClientInGame(clientBoss)) {
            decl String:steamTarget[32];
            GetClientAuthString(clientBoss, steamTarget, 32);
            if (StrEqual(steamTarget, split[4], true)) {
                PrintToChat(clientBoss, "%s Votre nouvelle recrut a refus‚ !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockAcceptationHopital(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (choice == 1) {
        if (viseJoueur(client)) {
            PrintToChat(client, "%s Veuillez patienter pendant que le joueur Accepte ou refuse sont recrutement !", "[Rp Magnetik : ->]");
            g_RecrutementMetierDocteur = CreateMenu(MenuHandler:25, MenuAction:28);
            decl String:titre[128];
            decl String:buffer[128];
            decl String:steamboss[32];
            GetClientAuthString(client, steamboss, 32);
            Format(titre, 128, "Validation de recrutement :\nVoulez vous etres : Docteur");
            SetMenuTitle(g_RecrutementMetierDocteur, titre);
            Format(buffer, 128, "1,%s,%d,%d", steamboss, 7, client);
            AddMenuItem(g_RecrutementMetierDocteur, buffer, "-> Accepter", 0);
            Format(buffer, 128, "2,%s,%d,%d", steamboss, 7, client);
            AddMenuItem(g_RecrutementMetierDocteur, buffer, "-> Refuser", 0);
            DisplayMenu(g_RecrutementMetierDocteur, GetClientAimTarget(client, true), 300);
        } else {
            PrintToChat(client, "%s Vous n'avez pas vis‚ quelqu'un ou vous ‚tes trop loin !", "[Rp Magnetik : ->]");
        }
    } else {
        if (choice == 2) {
            if (viseJoueur(client)) {
                PrintToChat(client, "%s Veuillez patienter pendant que le joueur Accepte ou refuse sont recrutement !", "[Rp Magnetik : ->]");
                g_RecrutementMetierInfirmier = CreateMenu(MenuHandler:25, MenuAction:28);
                decl String:titre[128];
                decl String:buffer[128];
                decl String:steamboss[32];
                GetClientAuthString(client, steamboss, 32);
                Format(titre, 128, "Validation de recrutement :\nVoulez vous etres : Infirmier");
                SetMenuTitle(g_RecrutementMetierInfirmier, titre);
                Format(buffer, 128, "1,%s,%d,%d", steamboss, 8, client);
                AddMenuItem(g_RecrutementMetierInfirmier, buffer, "-> Accepter", 0);
                Format(buffer, 128, "2,%s,%d,%d", steamboss, 8, client);
                AddMenuItem(g_RecrutementMetierInfirmier, buffer, "-> Refuser", 0);
                DisplayMenu(g_RecrutementMetierInfirmier, GetClientAimTarget(client, true), 300);
            }
            PrintToChat(client, "%s Vous n'avez pas vis‚ quelqu'un ou vous ‚tes trop loin !", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

menuRecruteHospital()
{
    panelhopital = CreatePanel(Handle:0);
    SetPanelTitle(panelhopital, "Choisir le metier :", false);
    SetPanelKeys(panelhopital, 1023);
    DrawPanelText(panelhopital, " ");
    DrawPanelText(panelhopital, "->1. Docteur");
    DrawPanelText(panelhopital, "->2. Infirmier");
    return 0;
}

bool:viseJoueur(client)
{
    if (GetClientAimTarget(client, true) != -1) {
        decl Float:vec[3];
        decl Float:vecTarget[3];
        GetClientAbsOrigin(client, vec);
        GetClientAbsOrigin(GetClientAimTarget(client, true), vecTarget);
        if (RoundToNearest(GetVectorDistance(vec, vecTarget, false)) < 100) {
            return true;
        }
    }
    return false;
}

FaireExploserEntite(entity)
{
    decl Float:posEnt[3];
    GetEntDataVector(entity, m_vecOrigin, posEnt);
    if (!IsModelPrecached("sprites/sprite_fire01.vmt")) {
        g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt", false);
    }
    TE_SetupExplosion(posEnt, g_ExplosionSprite, 20, 2, 0, 600, 6000, 171752, 67);
    TE_SendToAll(0);
    if (!IsSoundPrecached("ambient/explosions/explode_8.wav")) {
        PrecacheSound("ambient/explosions/explode_8.wav", false);
    }
    EmitAmbientSound("ambient/explosions/explode_8.wav", posEnt, entity, 75, 0, 1, 100, 0);
    new damage = 220;
    decl Float:vec[3];
    new distance = 0;
    new saVie = 0;
    new client = 1;
    while (client <= MaxClients) {
        new var1;
        if (IsClientInGame(client)) {
            GetClientAbsOrigin(client, vec);
            distance = RoundToNearest(GetVectorDistance(vec, posEnt, false));
            if (distance <= 300) {
                damage = 300 - distance * 100 / 300 * damage / 100;
                saVie = GetClientHealth(client);
                SlapPlayer(client, damage, false);
                if (saVie - damage < 1) {
                    ForcePlayerSuicide(client);
                }
                damage = 220;
                saVie = 0;
                client++;
            }
            client++;
        }
        client++;
    }
    return 0;
}

public Action:OnWeaponDropC4(client, iWeapon)
{
    decl String:className[64];
    if (IsValidEdict(iWeapon)) {
        GetEdictClassname(iWeapon, className, 64);
        if (!StrEqual(className, "weapon_c4", true)) {
            return Action:0;
        }
        if (EntRefToEntIndex(clientPropC4[client][0][0]) != -1) {
            new Handle:g_MenuC4 = CreateMenu(MenuHandler:39, MenuAction:28);
            SetMenuTitle(g_MenuC4, "| C4 BOMBE |");
            AddMenuItem(g_MenuC4, "1", "-> ON", 0);
            AddMenuItem(g_MenuC4, "2", "-> OFF", 0);
            DisplayMenu(g_MenuC4, client, 300);
        }
        return Action:0;
    }
    return Action:0;
}

public BlockFairePetterlabombe(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 3, 0, "", 0);
    new choix = StringToInt(parametre, 10);
    if (choix == 1) {
        FaireExploserEntite(clientPropC4[client][0][0]);
        RemoveEdict(clientPropC4[client][0][0]);
        clientPropC4[client] = -1;
    } else {
        RemoveEdict(clientPropC4[client][0][0]);
        clientPropC4[client] = -1;
    }
    return 0;
}

public Action:ToucheUnC4(weapon, client)
{
    if (IsValidEntity(weapon)) {
        decl String:sWeapon[32];
        GetEdictClassname(weapon, sWeapon, 32);
        if (StrEqual(sWeapon, "weapon_c4", true)) {
            new var1;
            if (client <= 0) {
                return Action:0;
            }
            new var2;
            if (clientPropC4[client][0][0] != -1) {
                return Action:0;
            }
            if (clientPropC4[client][0][0] != -1) {
                return Action:3;
            }
            new i = 1;
            while (i <= MaxClients) {
                new var3;
                if (IsClientInGame(i)) {
                    if (weapon == clientPropC4[i][0][0]) {
                        return Action:3;
                    }
                    i++;
                }
                i++;
            }
            clientPropC4[client] = weapon;
        }
    }
    return Action:0;
}

public Action:OnWeaponEquip(client, weapon)
{
    decl String:sWeapon[32];
    GetEdictClassname(weapon, sWeapon, 32);
    if (!StrEqual(sWeapon, "weapon_c4", true)) {
        return Action:0;
    }
    new var1;
    if (clientPropC4[client][0][0] != -1) {
        CancelClientMenu(client, true, Handle:0);
        return Action:0;
    }
    return Action:0;
}

PlayerStartSac(client)
{
    CancelClientMenu(client, false, Handle:0);
    OuvirMenuSac(client);
    return 0;
}

PlayerStartInSac(client)
{
    CancelClientMenu(client, false, Handle:0);
    CreateTimer(1, remettreDansSac, client, 0);
    return 0;
}

public Action:remettreDansSac(Handle:timer, client)
{
    new var1;
    if (IsClientConnected(client)) {
        MettreArmeDansSac(client);
        OuvirMenuSac(client);
    }
    return Action:0;
}

OuvirMenuSac(client)
{
    if (clientNbr1[client][0][0]) {
        new Handle:g_MenuSacPayer = CreateMenu(MenuHandler:105, MenuAction:28);
        SetMenuTitle(g_MenuSacPayer, "| Mon Sac d'objets |");
        decl String:buffer[8];
        decl String:InfoObjet[60];
        decl tabObjet[10];
        tabObjet[0] = clientItem1[client][0][0];
        tabObjet[4] = clientItem2[client][0][0];
        tabObjet[8] = clientItem3[client][0][0];
        tabObjet[12] = clientItem4[client][0][0];
        tabObjet[16] = clientItem5[client][0][0];
        tabObjet[20] = clientItem6[client][0][0];
        tabObjet[24] = clientItem7[client][0][0];
        tabObjet[28] = clientItem8[client][0][0];
        tabObjet[32] = clientItem9[client][0][0];
        tabObjet[36] = clientItem10[client][0][0];
        decl tabNbr[10];
        tabNbr[0] = clientNbr1[client][0][0];
        tabNbr[4] = clientNbr2[client][0][0];
        tabNbr[8] = clientNbr3[client][0][0];
        tabNbr[12] = clientNbr4[client][0][0];
        tabNbr[16] = clientNbr5[client][0][0];
        tabNbr[20] = clientNbr6[client][0][0];
        tabNbr[24] = clientNbr7[client][0][0];
        tabNbr[28] = clientNbr8[client][0][0];
        tabNbr[32] = clientNbr9[client][0][0];
        tabNbr[36] = clientNbr10[client][0][0];
        new i = 0;
        while (i < 10) {
            if (tabNbr[i]) {
                Format(buffer, 8, "%d,%d", i, tabObjet[i]);
                Format(InfoObjet, 60, "%d %s %d:%s", tabNbr[i], objetNom[tabObjet[i]][0][0], objetEffet[tabObjet[i]], objetFonction[tabObjet[i]][0][0]);
                AddMenuItem(g_MenuSacPayer, buffer, InfoObjet, 0);
                i++;
            }
            i++;
        }
        DisplayMenu(g_MenuSacPayer, client, 300);
    } else {
        PrintToChat(client, "%s Vous n'avez pas objets !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockSelectObjetInSac(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    decl String:split[12][12];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 10);
    new idsac = StringToInt(split[0][split], 10) + 1;
    new idobjet = StringToInt(split[4], 10);
    if (idobjet) {
        ActionObjetSurJoueur(client, idobjet, idsac);
    }
    return 0;
}

remettreOrdreSac(client, idsac)
{
    if (idsac == 1) {
        if (clientNbr1[client][0][0] == 1) {
            clientNbr1[client] = clientNbr2[client][0][0];
            clientItem1[client] = clientItem2[client][0][0];
            clientNbr2[client] = clientNbr3[client][0][0];
            clientItem2[client] = clientItem3[client][0][0];
            clientNbr3[client] = clientNbr4[client][0][0];
            clientItem3[client] = clientItem4[client][0][0];
            clientNbr4[client] = clientNbr5[client][0][0];
            clientItem4[client] = clientItem5[client][0][0];
            clientNbr5[client] = clientNbr6[client][0][0];
            clientItem5[client] = clientItem6[client][0][0];
            clientNbr6[client] = clientNbr7[client][0][0];
            clientItem6[client] = clientItem7[client][0][0];
            clientNbr7[client] = clientNbr8[client][0][0];
            clientItem7[client] = clientItem8[client][0][0];
            clientNbr8[client] = clientNbr9[client][0][0];
            clientItem8[client] = clientItem9[client][0][0];
            clientNbr9[client] = clientNbr10[client][0][0];
            clientItem9[client] = clientItem10[client][0][0];
            clientNbr10[client] = 0;
            clientItem10[client] = 0;
        } else {
            new var1 = clientNbr1[client];
            var1 = var1[0][0] + -1;
        }
    } else {
        if (idsac == 2) {
            if (clientNbr2[client][0][0] == 1) {
                clientNbr2[client] = clientNbr3[client][0][0];
                clientItem2[client] = clientItem3[client][0][0];
                clientNbr3[client] = clientNbr4[client][0][0];
                clientItem3[client] = clientItem4[client][0][0];
                clientNbr4[client] = clientNbr5[client][0][0];
                clientItem4[client] = clientItem5[client][0][0];
                clientNbr5[client] = clientNbr6[client][0][0];
                clientItem5[client] = clientItem6[client][0][0];
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var2 = clientNbr2[client];
                var2 = var2[0][0] + -1;
            }
        }
        if (idsac == 3) {
            if (clientNbr3[client][0][0] == 1) {
                clientNbr3[client] = clientNbr4[client][0][0];
                clientItem3[client] = clientItem4[client][0][0];
                clientNbr4[client] = clientNbr5[client][0][0];
                clientItem4[client] = clientItem5[client][0][0];
                clientNbr5[client] = clientNbr6[client][0][0];
                clientItem5[client] = clientItem6[client][0][0];
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var3 = clientNbr3[client];
                var3 = var3[0][0] + -1;
            }
        }
        if (idsac == 4) {
            if (clientNbr4[client][0][0] == 1) {
                clientNbr4[client] = clientNbr5[client][0][0];
                clientItem4[client] = clientItem5[client][0][0];
                clientNbr5[client] = clientNbr6[client][0][0];
                clientItem5[client] = clientItem6[client][0][0];
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var4 = clientNbr4[client];
                var4 = var4[0][0] + -1;
            }
        }
        if (idsac == 5) {
            if (clientNbr5[client][0][0] == 1) {
                clientNbr5[client] = clientNbr6[client][0][0];
                clientItem5[client] = clientItem6[client][0][0];
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var5 = clientNbr5[client];
                var5 = var5[0][0] + -1;
            }
        }
        if (idsac == 6) {
            if (clientNbr6[client][0][0] == 1) {
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var6 = clientNbr6[client];
                var6 = var6[0][0] + -1;
            }
        }
        if (idsac == 7) {
            if (clientNbr7[client][0][0] == 1) {
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var7 = clientNbr7[client];
                var7 = var7[0][0] + -1;
            }
        }
        if (idsac == 8) {
            if (clientNbr8[client][0][0] == 1) {
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var8 = clientNbr8[client];
                var8 = var8[0][0] + -1;
            }
        }
        if (idsac == 9) {
            if (clientNbr9[client][0][0] == 1) {
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var9 = clientNbr9[client];
                var9 = var9[0][0] + -1;
            }
        }
        if (idsac == 10) {
            if (clientNbr10[client][0][0] == 1) {
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            }
            new var10 = clientNbr10[client];
            var10 = var10[0][0] + -1;
        }
    }
    return 0;
}

bool:armeList(String:arme[], String:liste[][], size)
{
    new i = 0;
    while (i < size) {
        if (StrEqual(arme, liste[i], true)) {
            return true;
        }
        i++;
    }
    return false;
}

MettreArmeDansSac(client)
{
    decl String:weapon[32];
    GetClientWeapon(client, weapon, 32);
    new bool:existe = 0;
    new slot = 0;
    if (armeList(weapon, armePrimaire, 6)) {
        existe = 1;
        slot = 1;
    } else {
        if (armeList(weapon, armeSecondaire, 17)) {
            existe = 1;
            slot = 0;
        }
        if (armeList(weapon, armeProjectile, 3)) {
            existe = 1;
            slot = 3;
        }
        if (armeList(weapon, armeC4, 1)) {
            existe = 1;
            slot = 4;
        }
    }
    if (existe) {
        new bool:trouve = 0;
        new indexArme = 0;
        new index = 0;
        new item = 0;
        decl String:nomArme[64];
        while (index < 28 && trouve) {
            Format(nomArme, 64, "weapon_%s", objetNom[listObjetArmes[index][0][0]][0][0]);
            if (StrEqual(weapon, nomArme, true)) {
                trouve = 1;
                if (grenadeNapalm[client][0][0] == true) {
                    indexArme = 80;
                }
                indexArme = listObjetArmes[index][0][0];
            }
            index++;
        }
        if (trouve) {
            new iditem = TrouverPlaceDansSac(client, indexArme);
            if (0 < iditem) {
                item = GetPlayerWeaponSlot(client, slot);
                if (RemovePlayerItem(client, item)) {
                    if (slot == 4) {
                        clientPropC4[client] = -1;
                    }
                    if (grenadeNapalm[client][0][0] == true) {
                        grenadeNapalm[client] = 0;
                    }
                    MettreObjetDansSac(client, iditem, indexArme);
                    sauvegarderObjetSac(client);
                    PrintToChat(client, "%s %s a ‚t‚ rajout‚ dans ton sac !", "[Rp Magnetik : ->]", objetNom[indexArme][0][0]);
                } else {
                    PrintToChatAll("%s impossible de supprimer ton arme !", 172176);
                }
            } else {
                PrintToChat(client, "%s Vous avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Votre arme n'as pas etait trouv‚e !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Votre arme ne se range pas dans votre sac !", "[Rp Magnetik : ->]");
    }
    return 0;
}

MettreObjetDansSac(client, iditem, idobjet)
{
    if (iditem == 1) {
        if (clientNbr1[client][0][0]) {
            new var1 = clientNbr1[client];
            var1 = var1[0][0] + 1;
        } else {
            clientNbr1[client] = 1;
            clientItem1[client] = idobjet;
        }
    } else {
        if (iditem == 2) {
            if (clientNbr2[client][0][0]) {
                new var2 = clientNbr2[client];
                var2 = var2[0][0] + 1;
            } else {
                clientNbr2[client] = 1;
                clientItem2[client] = idobjet;
            }
        }
        if (iditem == 3) {
            if (clientNbr3[client][0][0]) {
                new var3 = clientNbr3[client];
                var3 = var3[0][0] + 1;
            } else {
                clientNbr3[client] = 1;
                clientItem3[client] = idobjet;
            }
        }
        if (iditem == 4) {
            if (clientNbr4[client][0][0]) {
                new var4 = clientNbr4[client];
                var4 = var4[0][0] + 1;
            } else {
                clientNbr4[client] = 1;
                clientItem4[client] = idobjet;
            }
        }
        if (iditem == 5) {
            if (clientNbr5[client][0][0]) {
                new var5 = clientNbr5[client];
                var5 = var5[0][0] + 1;
            } else {
                clientNbr5[client] = 1;
                clientItem5[client] = idobjet;
            }
        }
        if (iditem == 6) {
            if (clientNbr6[client][0][0]) {
                new var6 = clientNbr6[client];
                var6 = var6[0][0] + 1;
            } else {
                clientNbr6[client] = 1;
                clientItem6[client] = idobjet;
            }
        }
        if (iditem == 7) {
            if (clientNbr7[client][0][0]) {
                new var7 = clientNbr7[client];
                var7 = var7[0][0] + 1;
            } else {
                clientNbr7[client] = 1;
                clientItem7[client] = idobjet;
            }
        }
        if (iditem == 8) {
            if (clientNbr8[client][0][0]) {
                new var8 = clientNbr8[client];
                var8 = var8[0][0] + 1;
            } else {
                clientNbr8[client] = 1;
                clientItem8[client] = idobjet;
            }
        }
        if (iditem == 9) {
            if (clientNbr9[client][0][0]) {
                new var9 = clientNbr9[client];
                var9 = var9[0][0] + 1;
            } else {
                clientNbr9[client] = 1;
                clientItem9[client] = idobjet;
            }
        }
        if (iditem == 10) {
            if (clientNbr10[client][0][0]) {
                new var10 = clientNbr10[client];
                var10 = var10[0][0] + 1;
            }
            clientNbr10[client] = 1;
            clientItem10[client] = idobjet;
        }
    }
    return 0;
}

MettreObjetDansSacNB(client, iditem, idobjet, nombre)
{
    if (iditem == 1) {
        if (clientNbr1[client][0][0]) {
            new var1 = clientNbr1[client];
            var1 = var1[0][0] + nombre;
        } else {
            clientNbr1[client] = nombre;
            clientItem1[client] = idobjet;
        }
    } else {
        if (iditem == 2) {
            if (clientNbr2[client][0][0]) {
                new var2 = clientNbr2[client];
                var2 = var2[0][0] + nombre;
            } else {
                clientNbr2[client] = nombre;
                clientItem2[client] = idobjet;
            }
        }
        if (iditem == 3) {
            if (clientNbr3[client][0][0]) {
                new var3 = clientNbr3[client];
                var3 = var3[0][0] + nombre;
            } else {
                clientNbr3[client] = nombre;
                clientItem3[client] = idobjet;
            }
        }
        if (iditem == 4) {
            if (clientNbr4[client][0][0]) {
                new var4 = clientNbr4[client];
                var4 = var4[0][0] + nombre;
            } else {
                clientNbr4[client] = nombre;
                clientItem4[client] = idobjet;
            }
        }
        if (iditem == 5) {
            if (clientNbr5[client][0][0]) {
                new var5 = clientNbr5[client];
                var5 = var5[0][0] + nombre;
            } else {
                clientNbr5[client] = nombre;
                clientItem5[client] = idobjet;
            }
        }
        if (iditem == 6) {
            if (clientNbr6[client][0][0]) {
                new var6 = clientNbr6[client];
                var6 = var6[0][0] + nombre;
            } else {
                clientNbr6[client] = nombre;
                clientItem6[client] = idobjet;
            }
        }
        if (iditem == 7) {
            if (clientNbr7[client][0][0]) {
                new var7 = clientNbr7[client];
                var7 = var7[0][0] + nombre;
            } else {
                clientNbr7[client] = nombre;
                clientItem7[client] = idobjet;
            }
        }
        if (iditem == 8) {
            if (clientNbr8[client][0][0]) {
                new var8 = clientNbr8[client];
                var8 = var8[0][0] + nombre;
            } else {
                clientNbr8[client] = nombre;
                clientItem8[client] = idobjet;
            }
        }
        if (iditem == 9) {
            if (clientNbr9[client][0][0]) {
                new var9 = clientNbr9[client];
                var9 = var9[0][0] + nombre;
            } else {
                clientNbr9[client] = nombre;
                clientItem9[client] = idobjet;
            }
        }
        if (iditem == 10) {
            if (clientNbr10[client][0][0]) {
                new var10 = clientNbr10[client];
                var10 = var10[0][0] + nombre;
            }
            clientNbr10[client] = nombre;
            clientItem10[client] = idobjet;
        }
    }
    return 0;
}

TrouverPlaceDansSac(client, idObjet)
{
    new valeur = 0;
    decl tab[10];
    tab[0] = clientItem1[client][0][0];
    tab[4] = clientItem2[client][0][0];
    tab[8] = clientItem3[client][0][0];
    tab[12] = clientItem4[client][0][0];
    tab[16] = clientItem5[client][0][0];
    tab[20] = clientItem6[client][0][0];
    tab[24] = clientItem7[client][0][0];
    tab[28] = clientItem8[client][0][0];
    tab[32] = clientItem9[client][0][0];
    tab[36] = clientItem10[client][0][0];
    decl tabNbr[10];
    tabNbr[0] = clientNbr1[client][0][0];
    tabNbr[4] = clientNbr2[client][0][0];
    tabNbr[8] = clientNbr3[client][0][0];
    tabNbr[12] = clientNbr4[client][0][0];
    tabNbr[16] = clientNbr5[client][0][0];
    tabNbr[20] = clientNbr6[client][0][0];
    tabNbr[24] = clientNbr7[client][0][0];
    tabNbr[28] = clientNbr8[client][0][0];
    tabNbr[32] = clientNbr9[client][0][0];
    tabNbr[36] = clientNbr10[client][0][0];
    new bool:existe = 0;
    new i = 0;
    while (i < 10) {
        if (idObjet == tab[i]) {
            existe = 1;
            i++;
        }
        i++;
    }
    if (existe) {
        new k = 0;
        while (k < 10) {
            new var1;
            if (idObjet == tab[k]) {
                valeur = k + 1;
                return valeur;
            }
            k++;
        }
    } else {
        new j = 0;
        while (j < 10) {
            if (tab[j]) {
                j++;
            } else {
                valeur = j + 1;
                return valeur;
            }
            j++;
        }
    }
    return valeur;
}

TrouverPlaceDansSacNB(client, idObjet, nombre)
{
    new valeur = 0;
    decl tab[10];
    tab[0] = clientItem1[client][0][0];
    tab[4] = clientItem2[client][0][0];
    tab[8] = clientItem3[client][0][0];
    tab[12] = clientItem4[client][0][0];
    tab[16] = clientItem5[client][0][0];
    tab[20] = clientItem6[client][0][0];
    tab[24] = clientItem7[client][0][0];
    tab[28] = clientItem8[client][0][0];
    tab[32] = clientItem9[client][0][0];
    tab[36] = clientItem10[client][0][0];
    decl tabNbr[10];
    tabNbr[0] = clientNbr1[client][0][0];
    tabNbr[4] = clientNbr2[client][0][0];
    tabNbr[8] = clientNbr3[client][0][0];
    tabNbr[12] = clientNbr4[client][0][0];
    tabNbr[16] = clientNbr5[client][0][0];
    tabNbr[20] = clientNbr6[client][0][0];
    tabNbr[24] = clientNbr7[client][0][0];
    tabNbr[28] = clientNbr8[client][0][0];
    tabNbr[32] = clientNbr9[client][0][0];
    tabNbr[36] = clientNbr10[client][0][0];
    new bool:existe = 0;
    new i = 0;
    while (i < 10) {
        if (idObjet == tab[i]) {
            existe = 1;
            i++;
        }
        i++;
    }
    if (existe) {
        new k = 0;
        while (k < 10) {
            new var1;
            if (idObjet == tab[k]) {
                valeur = k + 1;
                return valeur;
            }
            k++;
        }
    } else {
        new j = 0;
        while (j < 10) {
            if (tab[j]) {
                j++;
            } else {
                valeur = j + 1;
                return valeur;
            }
            j++;
        }
    }
    return valeur;
}

ActionObjetSurJoueur(client, idobjet, idsac)
{
    if (StrEqual(objetFonction[idobjet][0][0], "Hp", true)) {
        if (!JoeurInscripEventG(client)) {
            if (objetEffet[idobjet][0][0] + GetClientHealth(client) < 501) {
                new vie = objetEffet[idobjet][0][0] + GetClientHealth(client);
                ExecHP(client, vie);
                remettreOrdreSac(client, idsac);
                PrintToChat(client, "%s Votre vie a augmenter !", "[Rp Magnetik : ->]");
            } else {
                PrintToChat(client, "%s Vous ne pouvez pas d‚passer 300 Hp !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Pas de vie suppl‚mentaire pendant l'event !", "[Rp Magnetik : ->]");
        }
    } else {
        if (StrEqual(objetFonction[idobjet][0][0], "Speed", true)) {
            remettreOrdreSac(client, idsac);
            ExecSpeed(client, objetEffet[idobjet][0][0]);
            PrintToChat(client, "%s %s a ‚t‚ retir‚ de votre sac !", "[Rp Magnetik : ->]", objetNom[idobjet][0][0]);
            CreateTimer(60, ExecSpeedDefault, client, 0);
        }
        if (StrEqual(objetFonction[idobjet][0][0], "Grav", true)) {
            remettreOrdreSac(client, idsac);
            ExecGravity(client, objetEffet[idobjet][0][0]);
            PrintToChat(client, "%s %s a ‚t‚ retir‚  de votre sac !", "[Rp Magnetik : ->]", objetNom[idobjet][0][0]);
            CreateTimer(60, ExecGravityDefault, client, 0);
        }
        new var1;
        if (StrEqual(objetFonction[idobjet][0][0], "ArPri", true)) {
            remettreOrdreSac(client, idsac);
            if (StrEqual(objetNom[idobjet][0][0], "Kevlar", true)) {
                GivePlayerItem(client, "item_assaultsuit", 0);
            } else {
                if (StrEqual(objetNom[idobjet][0][0], "Grenade Napalm", true)) {
                    grenadeNapalm[client] = 1;
                    GivePlayerItem(client, "weapon_hegrenade", 0);
                }
                decl String:nomArme[64];
                Format(nomArme, 64, "weapon_%s", objetNom[idobjet][0][0]);
                GivePlayerItem(client, nomArme, 0);
            }
            sauvegarderObjetSac(client);
            PrintToChat(client, "%s %s a ‚t‚ retir‚ de votre sac !", "[Rp Magnetik : ->]", objetNom[idobjet][0][0]);
        }
        if (StrEqual(objetFonction[idobjet][0][0], "Porte", true)) {
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                new index = porteExisteDansLaDB(entity);
                if (index != -1) {
                    if (ProcheJoueurPorte(entity, client)) {
                        remettreOrdreSac(client, idsac);
                        CrochetageDePorte(entity, client);
                    } else {
                        PrintToChat(client, "%s Vous ˆtes trop loin de la porte !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Porte non enregistr‚e dans la DB !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous n'avez pas vis‚ une porte !", "[Rp Magnetik : ->]");
            }
        }
        if (StrEqual(objetFonction[idobjet][0][0], "Skins", true)) {
            remettreOrdreSac(client, idsac);
            if (idobjet == 65) {
                strcopy(clientSkin[client][0][0], 32, "50cent");
                SauvegarderLeSkinDB(client, "50cent");
                DonnerUnSkinJoueur(client);
            } else {
                if (idobjet == 66) {
                    strcopy(clientSkin[client][0][0], 32, "vin_diesel");
                    SauvegarderLeSkinDB(client, "vin_diesel");
                    DonnerUnSkinJoueur(client);
                }
                if (idobjet == 67) {
                    strcopy(clientSkin[client][0][0], 32, "bloodz");
                    SauvegarderLeSkinDB(client, "bloodz");
                    DonnerUnSkinJoueur(client);
                }
                if (idobjet == 68) {
                    strcopy(clientSkin[client][0][0], 32, "cripz");
                    SauvegarderLeSkinDB(client, "cripz");
                    DonnerUnSkinJoueur(client);
                }
                if (idobjet == 69) {
                    strcopy(clientSkin[client][0][0], 32, "niko_bellic");
                    SauvegarderLeSkinDB(client, "niko_bellic");
                    DonnerUnSkinJoueur(client);
                }
                if (idobjet == 70) {
                    strcopy(clientSkin[client][0][0], 32, "murray");
                    SauvegarderLeSkinDB(client, "murray");
                    DonnerUnSkinJoueur(client);
                }
                if (idobjet == 71) {
                    strcopy(clientSkin[client][0][0], 32, "greaser");
                    SauvegarderLeSkinDB(client, "greaser");
                    DonnerUnSkinJoueur(client);
                }
            }
        }
        if (StrEqual(objetFonction[idobjet][0][0], "FP", true)) {
            new level = clientPrecision[client][0][0];
            if (level < 100) {
                remettreOrdreSac(client, idsac);
                new var2 = clientPrecision[client];
                var2 = var2[0][0] + 1;
                voirMonLevelKnife(client);
            } else {
                PrintToChat(client, "%s Vous ne pouvez pas d‚passer le level de pr‚cision de 100/100 !", "[Rp Magnetik : ->]");
            }
        }
        if (StrEqual(objetFonction[idobjet][0][0], "Lame", true)) {
            new level = clientLevelKnife[client][0][0];
            if (level < 100) {
                remettreOrdreSac(client, idsac);
                new var3 = clientLevelKnife[client];
                var3 = var3[0][0] + 1;
                voirMonLevelKnife(client);
            } else {
                PrintToChat(client, "%s Vous ne pouvez pas d‚passer le level knife de 100/100 !", "[Rp Magnetik : ->]");
            }
        }
        if (StrEqual(objetFonction[idobjet][0][0], "LR", true)) {
            new level = clientLevelKnife[client][0][0];
            if (level < 150) {
                remettreOrdreSac(client, idsac);
                new var4 = clientLevelKnife[client];
                var4 = var4[0][0] + 1;
                voirMonLevelKnife(client);
            } else {
                PrintToChat(client, "%s Vous ne pouvez pas d‚passer le level knife de 150/100 !", "[Rp Magnetik : ->]");
            }
        }
        if (StrEqual(objetFonction[idobjet][0][0], "Niveau", true)) {
            if (NiveauForceSer(client, objetEffet[idobjet][0][0])) {
                PrintToChat(client, "%s Porte renforcer niveau %d !", "[Rp Magnetik : ->]", objetEffet[idobjet]);
                remettreOrdreSac(client, idsac);
            }
        }
        if (StrEqual(objetNom[idobjet][0][0], "Cut Napalm", true)) {
            remettreOrdreSac(client, idsac);
            clientCutNapalm[client] = 1;
            PrintToChat(client, "%s Cut Napalm activ‚ pendant 40 sec !", "[Rp Magnetik : ->]");
            CreateTimer(40, ExecCutNapalm, client, 0);
        }
        if (StrEqual(objetNom[idobjet][0][0], "Poison", true)) {
            if (ActivePoisson(client)) {
                remettreOrdreSac(client, idsac);
            }
        }
        if (StrEqual(objetNom[idobjet][0][0], "Antidote", true)) {
            if (ActiveAntidote(client)) {
                remettreOrdreSac(client, idsac);
            }
        }
    }
    PlayerStartSac(client);
    return 0;
}

public ExecHP(client, health)
{
    SetEntityHealth(client, health);
    return 0;
}

public Action:ExecCutNapalm(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        clientCutNapalm[client] = 0;
        PrintToChat(client, "%s Fin du Cut Napalm !", "[Rp Magnetik : ->]");
    }
    return Action:0;
}

public ExecSpeed(client, speed)
{
    new var1;
    if (IsClientInGame(client)) {
        decl String:spTotal[8];
        Format(spTotal, 6, "1.%d", speed);
        new Float:vitesse = StringToFloat(spTotal);
        SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", vitesse);
    }
    return 0;
}

public Action:ExecSpeedDefault(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", 1);
        PrintToChat(client, "%s Le speed ne fait plus effet !", "[Rp Magnetik : ->]");
    }
    return Action:0;
}

public ExecGravity(client, gravity)
{
    new var1;
    if (IsClientInGame(client)) {
        decl String:graTotal[8];
        Format(graTotal, 6, "0.%d", gravity);
        new Float:total = StringToFloat(graTotal);
        SetEntPropFloat(client, PropType:1, "m_flGravity", total);
    }
    return 0;
}

public Action:ExecGravityDefault(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        SetEntPropFloat(client, PropType:1, "m_flGravity", 1);
        PrintToChat(client, "%s La gravit‚ ne fait plus effet !", "[Rp Magnetik : ->]");
    }
    return Action:0;
}

public Action:Event_PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new var1;
    if (GetClientTeam(client) > 1) {
        if (!clientInJail[client][0][0]) {
            new g_Entity = CreateEntityByName("player_weaponstrip", -1);
            AcceptEntityInput(g_Entity, "StripWeaponsAndSuit", client, -1, 0);
            AcceptEntityInput(g_Entity, "Kill", -1, -1, 0);
            CreateTimer(0.5, donnerUnKnife, client, 0);
        }
        nextactivetime[client] = GetGameTime();
        DonnerUnSkinJoueur(client);
    }
    if (GetClientTeam(client) != clientTeam[client][0][0]) {
        CS_SwitchTeam(client, clientTeam[client][0][0]);
    }
    new sonidmetier = clientIdMetier[client][0][0];
    if (sonidmetier == 4) {
        if (!JoeurInscripEventG(client)) {
            SetEntityHealth(client, 500);
            GivePlayerItem(client, "item_assaultsuit", 0);
        }
        new place = TrouverPlaceDansSac(client, 49);
        new valeur = TrouverLeNombreDObjet(client, 49);
        if (valeur < 1) {
            if (0 < place) {
                MettreObjetDansSac(client, place, 49);
                PrintToChat(client, "%s M3 Rajout‚ dans ton sac !", "[Rp Magnetik : ->]");
            }
        }
    } else {
        if (sonidmetier == 5) {
            if (!JoeurInscripEventG(client)) {
                SetEntityHealth(client, 400);
                GivePlayerItem(client, "item_assaultsuit", 0);
            }
            new place = TrouverPlaceDansSac(client, 49);
            new valeur = TrouverLeNombreDObjet(client, 49);
            if (valeur < 1) {
                if (0 < place) {
                    MettreObjetDansSac(client, place, 49);
                    PrintToChat(client, "%s M3 Rajout‚ dans ton sac !", "[Rp Magnetik : ->]");
                }
            }
        }
        if (sonidmetier == 2) {
            if (!JoeurInscripEventG(client)) {
                SetEntityHealth(client, 2000);
                GivePlayerItem(client, "item_assaultsuit", 0);
            }
            new place = TrouverPlaceDansSac(client, 37);
            new valeur = TrouverLeNombreDObjet(client, 37);
            if (valeur < 1) {
                if (0 < place) {
                    MettreObjetDansSac(client, place, 37);
                    PrintToChat(client, "%s Deagle Rajout‚ dans ton sac !", "[Rp Magnetik : ->]");
                }
            }
            valeur = TrouverLeNombreDObjet(client, 45);
            if (valeur < 1) {
                place = TrouverPlaceDansSac(client, 45);
                if (0 < place) {
                    MettreObjetDansSac(client, place, 45);
                    PrintToChat(client, "%s M4 Rajout‚ dans ton sac !", "[Rp Magnetik : ->]");
                }
            }
        }
        if (sonidmetier == 3) {
            if (!JoeurInscripEventG(client)) {
                SetEntityHealth(client, 500);
                GivePlayerItem(client, "item_assaultsuit", 0);
            }
            new place = TrouverPlaceDansSac(client, 37);
            new valeur = TrouverLeNombreDObjet(client, 37);
            if (valeur < 1) {
                if (0 < place) {
                    MettreObjetDansSac(client, place, 37);
                    PrintToChat(client, "%s Deagle Rajout‚ dans ton sac !", "[Rp Magnetik : ->]");
                }
            }
            valeur = TrouverLeNombreDObjet(client, 45);
            if (valeur < 1) {
                place = TrouverPlaceDansSac(client, 45);
                if (0 < place) {
                    MettreObjetDansSac(client, place, 45);
                    PrintToChat(client, "%s M4 Rajout‚ dans ton sac !", "[Rp Magnetik : ->]");
                }
            }
        }
    }
    clientPropC4[client] = -1;
    return Action:0;
}

public Action:Event_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
    decl String:weaponName[32];
    GetEventString(event, "weapon", weaponName, 32);
    if (StrEqual(weaponName, "hegrenade", true)) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new clientAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        new damage = GetEventInt(event, "dmg_health");
        if (grenadeNapalm[clientAttacker][0][0]) {
            grenadeNapalm[clientAttacker] = 0;
            if (damage <= 30) {
                IgniteEntity(client, 12, false, 0, false);
            }
            if (damage > 71) {
                IgniteEntity(client, 9, false, 0, false);
            }
            if (damage > 51) {
                IgniteEntity(client, 6, false, 0, false);
            }
            if (damage >= 31) {
                IgniteEntity(client, 3, false, 0, false);
            }
        }
    }
    return Action:0;
}

public Action:Event_PlayerTeam(Handle:event, String:name[], bool:dontBroadcast)
{
    if (!GetEventBool(event, "silent")) {
        return Action:3;
    }
    return Action:0;
}


/* ERROR! unknown operator */
 function "OnPlayerRunCmd" (number 153)
ClearLesTotalKill()
{
    new client = 1;
    while (client <= MaxClients) {
        new var1;
        if (IsClientInGame(client)) {
            clientTotalKill[client] = 0;
        }
        client++;
    }
    decl String:req[256];
    decl String:error[256];
    Format(req, 255, "UPDATE Playersup SET totalKill = 0");
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Admin", "Impossible de remettre a zero les total des kill / jour (ClearLesTotalKill) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}

public Action:ResetDelay(Handle:timer, client)
{
    buttondelay[client] = 0;
    return Action:0;
}

public Action:Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new attack = 0;
    if (GetEventInt(event, "attacker")) {
        attack = GetClientOfUserId(GetEventInt(event, "attacker"));
    }
    new var1;
    if (attack) {
        decl String:NameVictime[32];
        GetClientName(client, NameVictime, 32);
        decl String:NameAttacker[32];
        GetClientName(attack, NameAttacker, 32);
        strcopy(clientMaTuer[client][0][0], 32, NameAttacker);
        strcopy(clientJaiTuer[attack][0][0], 32, NameVictime);
        new var2 = clientKill[attack];
        var2 = var2[0][0] + 1;
        new var3 = clientTotalKill[attack];
        var3 = var3[0][0] + 1;
        if (GetTeamClientCount(3) < 1) {
            new argentAttack = clientCash[attack][0][0];
            if (argentAttack >= 100) {
                new var4 = clientCash[attack];
                var4 = var4[0][0] + -100;
                new var5 = clientCash[client];
                var5 = var5[0][0] + 100;
                PrintToChat(client, "%s +100$ a ‚t‚ verse pour dommage et int‚rˆt !", "[Rp Magnetik : ->]");
                PrintToChat(attack, "%s -100$ a ‚t‚ retire pour dommage et int‚rˆt !", "[Rp Magnetik : ->]");
            } else {
                if (0 < argentAttack) {
                    new var6 = clientCash[attack];
                    var6 = var6[0][0] - argentAttack;
                    new var7 = clientCash[client];
                    var7 = var7[0][0] + argentAttack;
                    PrintToChat(client, "%s +%d$ a ‚t‚ verse pour dommage et int‚rˆt !", "[Rp Magnetik : ->]", argentAttack);
                    PrintToChat(attack, "%s -%d$ a ‚t‚ retire pour dommage et int‚rˆt !", "[Rp Magnetik : ->]", argentAttack);
                }
            }
        }
    }
    new var8 = clientDead[client];
    var8 = var8[0][0] + 1;
    CreateTimer(10, choisirTeamSpawn, client, 0);
    PrintToChat(client, "%s Tu va revivre dans 10 sec !", "[Rp Magnetik : ->]");
    SetEventBroadcast(event, true);
    CloseHandle(event);
    return Action:0;
}

public Action:Event_SayCallback(client, String:command[], argc)
{
    new var1;
    if (client) {
        return Action:0;
    }
    decl String:message[32];
    decl String:split[8][16];
    GetCmdArgString(message, 32);
    StripQuotes(message);
    new zone = indexZoneDuJoueur(client);
    if (typeDeZone[zone][0][0] == 4) {
        new SonIdMetier = clientIdMetier[client][0][0];
        if (!inList(SonIdMetier, listMetierSecu, 4)) {
            return Action:3;
        }
    }
    ExplodeString(message, " ", split, 2, 16);
    new var2;
    if (StrEqual(split[0][split], "!give", true)) {
        new valeur = StringToInt(split[4], 10);
        new var3;
        if (valeur > 0) {
            if (clientTempsPasse[client][0][0] > 120) {
                DonnerArgentPlayerVise(client, valeur);
            } else {
                PrintToChat(client, "%s il faut 2 heures de jeu avant de pouvoir donner de l'argent !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Argument incorrect ! Exemple (!give 500).", "[Rp Magnetik : ->]");
        }
        return Action:3;
    }
    if (StrEqual(message, "!adminrp", true)) {
        AdminRolePlayStart(client);
        return Action:3;
    }
    if (StrEqual(message, "!level", true)) {
        voirMonLevelKnife(client);
        return Action:3;
    }
    if (StrEqual(message, "!enquete", true)) {
        AfficherInformationJoueur(client);
        return Action:3;
    }
    if (StrEqual(message, "!event", true)) {
        AfficheMenuEvent(client);
        return Action:3;
    }
    if (StrEqual(message, "!vol", true)) {
        PickUPArgentJoueur(client);
        return Action:3;
    }
    if (StrEqual(message, "!out", true)) {
        SortirJoueurDuPlanque(client);
        return Action:3;
    }
    new var4;
    if (StrEqual(message, "!recrut", true)) {
        RecrutementUnJoueur(client);
        return Action:3;
    }
    new var5;
    if (StrEqual(message, "!sac", true)) {
        PlayerStartSac(client);
        return Action:3;
    }
    new var6;
    if (StrEqual(message, "!danssac", true)) {
        PlayerStartInSac(client);
        return Action:3;
    }
    new var7;
    if (StrEqual(message, "!acheter", true)) {
        PlayerStartAcheterObjets(client);
        return Action:3;
    }
    new var8;
    if (StrEqual(message, "!vendre", true)) {
        PlayerStartVendreObjets(client);
        return Action:3;
    }
    new var9;
    if (StrEqual(message, "!flic", true)) {
        PlayerStartFlic(client);
        return Action:3;
    }
    if (StrEqual(message, "!jail", true)) {
        PlayerMettreEnJail(client);
        return Action:3;
    }
    if (StrEqual(message, "!porte", true)) {
        AfficherInformationPorte(client);
        return Action:3;
    }
    new var10;
    if (StrEqual(message, "!cle", true)) {
        LockUnePorte(client);
        return Action:3;
    }
    new var11;
    if (StrEqual(message, "!givekey", true)) {
        DonnerUnDoubleDesCle(client);
        return Action:3;
    }
    new var12;
    if (StrEqual(message, "!retirecle", true)) {
        RetirerUnDoubleDesCle(client);
        return Action:3;
    }
    if (StrEqual(message, "!c4", true)) {
        decl String:steamid[32];
        GetClientAuthString(client, steamid, 32);
        if (StrEqual(steamid, "STEAM_0:0:26796846", true)) {
            GivePlayerItem(client, "weapon_c4", 0);
            return Action:3;
        }
    }
    if (StrEqual(message, "!test", true)) {
        if (inListAdmin(client)) {
            decl Float:vecOrigin[3];
            GetEntDataVector(client, m_vecOrigin, vecOrigin);
            PrintToChat(client, "X: %f  Y: %f  Z: %f ", vecOrigin, vecOrigin[4], vecOrigin[8]);
            PrintToChat(client, "l'index que tu vise est : %d ", GetClientAimTarget(client, false));
            PrintToChat(client, "le dernier que tu as tuer : %s ", clientJaiTuer[client][0][0]);
            PrintToChat(client, "le dernier qui ta tuer : %s ", clientMaTuer[client][0][0]);
            PrintToChat(client, "le temps passer : %d minutes ", clientTempsPasse[client]);
            PrintToChat(client, "le nombre de kill : %d ", clientTotalKill[client]);
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                decl String:strModel[152];
                GetEntPropString(entity, PropType:1, "m_ModelName", strModel, 150);
                PrintToChat(client, "%s index prop : %s", "[Rp Magnetik : ->]", strModel);
                new ent = GetEntPropEnt(entity, PropType:0, "m_nModelIndex");
                PrintToChat(client, "%s index prop : %d", "[Rp Magnetik : ->]", ent);
            }
        } else {
            PrintToChat(client, "tu n'es pas admin");
        }
        return Action:3;
    }
    return Action:0;
}

public Action:Event_SayTeam(client, String:command[], argc)
{
    new var1;
    if (client) {
        return Action:0;
    }
    decl String:Name[32];
    GetClientName(client, Name, 32);
    decl Float:vec[3];
    decl Float:vecTarget[3];
    GetClientAbsOrigin(client, vec);
    decl String:message[1024];
    GetCmdArgString(message, 1024);
    StripQuotes(message);
    new clientTarget = 1;
    while (clientTarget <= MaxClients) {
        new var2;
        if (IsClientInGame(clientTarget)) {
            GetClientAbsOrigin(clientTarget, vecTarget);
            new var3;
            if (RoundToNearest(GetVectorDistance(vec, vecTarget, false)) < 200) {
                PrintToChat(clientTarget, "(Message Zone)  %s :  %s", Name, message);
                clientTarget++;
            }
            clientTarget++;
        }
        clientTarget++;
    }
    return Action:3;
}


/* ERROR! unknown operator */
 function "OnTakeDamage" (number 159)
public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, players[], playersNum, bool:reliable, bool:init)
{
    decl String:message[256];
    BfReadString(bf, message, 256, false);
    if (StrContains(message, "teammate_attack", true) != -1) {
        return Action:3;
    }
    return Action:0;
}

voirMonLevelKnife(client)
{
    PrintToChat(client, "%s Votre level knife est de %d/100", "[Rp Magnetik : ->]", clientLevelKnife[client]);
    PrintToChat(client, "%s Votre level de pr‚cision est de %d/100", "[Rp Magnetik : ->]", clientPrecision[client]);
    return 0;
}

TrouverLeNombreDObjet(client, idObjet)
{
    new valeur = 0;
    decl tab[10];
    tab[0] = clientItem1[client][0][0];
    tab[4] = clientItem2[client][0][0];
    tab[8] = clientItem3[client][0][0];
    tab[12] = clientItem4[client][0][0];
    tab[16] = clientItem5[client][0][0];
    tab[20] = clientItem6[client][0][0];
    tab[24] = clientItem7[client][0][0];
    tab[28] = clientItem8[client][0][0];
    tab[32] = clientItem9[client][0][0];
    tab[36] = clientItem10[client][0][0];
    new j = 0;
    while (j < 10) {
        if (idObjet == tab[j]) {
            valeur += 1;
            j++;
        }
        j++;
    }
    return valeur;
}

public Action:donnerUnKnife(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        GivePlayerItem(client, "weapon_knife", 0);
    }
    return Action:0;
}

OpenMenu(client, Handle:panel, MenuHandler:functionHandler)
{
    CancelClientMenu(client, false, Handle:0);
    SendPanelToClient(panel, client, functionHandler, 0);
    return 0;
}

public Action:choisirTeamSpawn(Handle:timer, client)
{
    new var1;
    if (IsClientConnected(client)) {
        if (clientInJail[client][0][0]) {
            CS_SwitchTeam(client, clientTeam[client][0][0]);
            CS_RespawnPlayer(client);
            teleporterJoueurEnJail(client);
        }
        CS_SwitchTeam(client, clientTeam[client][0][0]);
        CS_RespawnPlayer(client);
    }
    return Action:0;
}

DonnerArgentPlayerVise(client, valeur)
{
    new var1;
    if (IsClientInGame(client)) {
        if (viseJoueur(client)) {
            if (clientCash[client][0][0] >= valeur) {
                new clientTarget = GetClientAimTarget(client, true);
                decl String:steamTarget[32];
                GetClientAuthString(clientTarget, steamTarget, 32);
                decl String:nameTarget[32];
                GetClientName(clientTarget, nameTarget, 32);
                new Handle:g_MenuDonnerArgent = CreateMenu(MenuHandler:23, MenuAction:28);
                decl String:titre[128];
                Format(titre, 128, "| Donner Argent |\n=> %d $ \nA => %s", valeur, nameTarget);
                SetMenuTitle(g_MenuDonnerArgent, titre);
                decl String:buffer[128];
                Format(buffer, 128, "1,%s,%d,%d", steamTarget, clientTarget, valeur);
                AddMenuItem(g_MenuDonnerArgent, buffer, "-> Accepter", 0);
                Format(buffer, 128, "2,%s,%d,%d", steamTarget, clientTarget, valeur);
                AddMenuItem(g_MenuDonnerArgent, buffer, "-> Refuser", 0);
                DisplayMenu(g_MenuDonnerArgent, client, 300);
            } else {
                PrintToChat(client, "%s Vous n'avez pas assez d'argents !", "[Rp Magnetik : ->]");
            }
        }
        PrintToChat(client, "%s Vous n'avez pas vis‚ quelqu'un ou vous ˆtes trop loin !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockConfirmationArgent(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    new valeur = StringToInt(split[0][split], 10);
    new clientTarget = StringToInt(split[8], 10);
    new argent = StringToInt(split[12], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientTarget)) {
            decl String:steamTarget[32];
            GetClientAuthString(clientTarget, steamTarget, 32);
            if (StrEqual(steamTarget, split[4], true)) {
                if (posDeuxJoueur(client, clientTarget)) {
                    decl String:nameClient[32];
                    decl String:nameClient2[32];
                    GetClientName(client, nameClient, 32);
                    GetClientName(clientTarget, nameClient2, 32);
                    decl String:steamID[32];
                    GetClientAuthString(client, steamID, 32);
                    new var2 = clientCash[client];
                    var2 = var2[0][0] - argent;
                    new var3 = clientCash[clientTarget];
                    var3 = var3[0][0] + argent;
                    sauvegarderArgentClient(client);
                    sauvegarderArgentClient(clientTarget);
                    PrintToChat(clientTarget, "%s Vous venez de recevoir %d $ par %s !", "[Rp Magnetik : ->]", argent, nameClient);
                    Log("Roleplay Argent", "%s ->(%s) … donner %d $ … %s -> (%s)", nameClient, steamID, argent, nameClient2, steamTarget);
                }
                PrintToChat(client, "%s Vous ˆtes trop loin !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

DonnerVieSecurite(client)
{
    new sonidmetier = clientIdMetier[client][0][0];
    new var1;
    if (sonidmetier == 5) {
        if (!JoeurInscripEventG(client)) {
            if (ProcheJoueurPorte(510, client)) {
                SetEntityHealth(client, 500);
                GivePlayerItem(client, "item_assaultsuit", 0);
            }
        }
    } else {
        if (sonidmetier == 2) {
            if (ProcheJoueurPorte(510, client)) {
                SetEntityHealth(client, 2000);
                GivePlayerItem(client, "item_assaultsuit", 0);
            }
        }
    }
    return 0;
}

public Action:Timer_CheckAudio(Handle:timer, data)
{
    decl Float:vec[3];
    decl Float:vecTarget[3];
    new client = 1;
    while (client <= MaxClients) {
        new var1;
        if (IsClientInGame(client)) {
            GetClientAbsOrigin(client, vec);
            new iclient = 1;
            while (iclient <= MaxClients) {
                new var2;
                if (IsClientInGame(iclient)) {
                    GetClientAbsOrigin(iclient, vecTarget);
                    new var3;
                    if (RoundToNearest(GetVectorDistance(vec, vecTarget, false)) < 200) {
                        if (clientInJail[client][0][0]) {
                            if (clientInJail[iclient][0][0]) {
                                SetListenOverride(client, iclient, ListenOverride:1);
                                SetListenOverride(iclient, client, ListenOverride:1);
                                iclient++;
                            } else {
                                SetListenOverride(client, iclient, ListenOverride:2);
                                SetListenOverride(iclient, client, ListenOverride:1);
                                iclient++;
                            }
                            iclient++;
                        } else {
                            if (clientInJail[iclient][0][0]) {
                                SetListenOverride(client, iclient, ListenOverride:1);
                                SetListenOverride(iclient, client, ListenOverride:2);
                                iclient++;
                            }
                            SetListenOverride(client, iclient, ListenOverride:2);
                            SetListenOverride(iclient, client, ListenOverride:2);
                            iclient++;
                        }
                        iclient++;
                    }
                    SetListenOverride(client, iclient, ListenOverride:1);
                    SetListenOverride(iclient, client, ListenOverride:1);
                    iclient++;
                }
                iclient++;
            }
            client++;
        }
        client++;
    }
    return Action:0;
}

CreationMenuPourAcheterObjets()
{
    decl String:buffer[8];
    decl String:InfoObjet[60];
    g_MenuMafiaFReZ = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuMafiaFReZ, "Acheter une arme:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 35) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuMafiaFReZ, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuMafiaIta = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuMafiaIta, "Acheter une arme:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 37) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuMafiaIta, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuMafiaRusse = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuMafiaRusse, "Acheter une arme:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 39) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuMafiaRusse, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuMedic = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuMedic, "Acheter un Medic:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 6) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuMedic, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuPizza = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuPizza, "Acheter une Pizza :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 9) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuPizza, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuMoniteur = CreateMenu(MenuHandler:15, MenuAction:28);
    SetMenuTitle(g_MenuMoniteur, "Acheter Moniteur :");
    AddMenuItem(g_MenuMoniteur, "1", "Port d'arme secondaire 2500$", 0);
    AddMenuItem(g_MenuMoniteur, "2", "Port d'arme primaire 3500$", 0);
    AddMenuItem(g_MenuMoniteur, "3", "Pr‚cision de tir 30$/unite", 0);
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 11) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuMoniteur, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuBanquier = CreateMenu(MenuHandler:3, MenuAction:28);
    SetMenuTitle(g_MenuBanquier, "Achats du Banquier :");
    AddMenuItem(g_MenuBanquier, "1", "D‚po d'objets en banque 2500$", 0);
    AddMenuItem(g_MenuBanquier, "2", "Carte de credit 4500$", 0);
    AddMenuItem(g_MenuBanquier, "3", "R.I.B 3500$", 0);
    g_MenuSerrurier = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuSerrurier, "| Achats du Serrurier |\nPour renforcer une serrure\nIl faut augmenter par palier N1 -> N2 ->...");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 15) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuSerrurier, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuCoutelier = CreateMenu(MenuHandler:5, MenuAction:28);
    SetMenuTitle(g_MenuCoutelier, "Achats du coutelier :");
    AddMenuItem(g_MenuCoutelier, "1", "Level knife 20$/unite", 0);
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 17) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuCoutelier, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuArme = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuArme, "Acheter une Arme :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 19) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuArme, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuExplosif = CreateMenu(MenuHandler:7, MenuAction:28);
    SetMenuTitle(g_MenuExplosif, "Acheter de l'explosif :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 21) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuExplosif, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuDetective = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuDetective, "Achats du D‚tective :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 23) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuDetective, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuIkea = CreateMenu(MenuHandler:9, MenuAction:28);
    SetMenuTitle(g_MenuIkea, "| Acheter des objets d'Ikea |");
    AddMenuItem(g_MenuIkea, "1", "Un distributeur 200$", 0);
    AddMenuItem(g_MenuIkea, "2", "Un canap‚ 50$", 0);
    AddMenuItem(g_MenuIkea, "3", "Une bibliothŠque 100$", 0);
    AddMenuItem(g_MenuIkea, "4", "Une machine … laver 35$", 0);
    AddMenuItem(g_MenuIkea, "5", "Une gazini‚re 180$", 0);
    AddMenuItem(g_MenuIkea, "6", "Une table … manger 150$", 0);
    AddMenuItem(g_MenuIkea, "7", "Une chaise 25$", 0);
    AddMenuItem(g_MenuIkea, "8", "Un pot de fleur 15$", 0);
    AddMenuItem(g_MenuIkea, "9", "Une table en bois 125$", 0);
    AddMenuItem(g_MenuIkea, "10", "Un grand placard  200$", 0);
    g_MenuBoisson = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuBoisson, "Acheter une Boisson :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 27) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuBoisson, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuDrogue = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuDrogue, "Acheter de la Drogue :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 29) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuDrogue, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuSkins = CreateMenu(MenuHandler:17, MenuAction:28);
    SetMenuTitle(g_MenuSkins, "Acheter un Habit:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 31) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuSkins, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    return 0;
}

PlayerStartAcheterObjets(client)
{
    if (clientInJail[client][0][0]) {
        PrintToChat(client, "%s Vous ˆtes en Prison !", "[Rp Magnetik : ->]");
    } else {
        new SonIdMetier = clientIdMetier[client][0][0];
        new var1;
        if (SonIdMetier == 6) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuMedic, client, 300);
        } else {
            new var2;
            if (SonIdMetier == 9) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuPizza, client, 300);
            }
            new var3;
            if (SonIdMetier == 11) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuMoniteur, client, 300);
            }
            new var4;
            if (SonIdMetier == 13) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuBanquier, client, 300);
            }
            new var5;
            if (SonIdMetier == 15) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuSerrurier, client, 300);
            }
            new var6;
            if (SonIdMetier == 17) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuCoutelier, client, 300);
            }
            new var7;
            if (SonIdMetier == 19) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuArme, client, 300);
            }
            new var8;
            if (SonIdMetier == 21) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuExplosif, client, 300);
            }
            new var9;
            if (SonIdMetier == 23) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuDetective, client, 300);
            }
            new var10;
            if (SonIdMetier == 25) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuIkea, client, 300);
            }
            new var11;
            if (SonIdMetier == 27) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuBoisson, client, 300);
            }
            new var12;
            if (SonIdMetier == 29) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuDrogue, client, 300);
            }
            new var13;
            if (SonIdMetier == 31) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuSkins, client, 300);
            }
            new var14;
            if (SonIdMetier == 35) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuMafiaFReZ, client, 300);
            }
            new var15;
            if (SonIdMetier == 37) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuMafiaIta, client, 300);
            }
            new var16;
            if (SonIdMetier == 39) {
                CancelClientMenu(client, false, Handle:0);
                DisplayMenu(g_MenuMafiaRusse, client, 300);
            }
            if (SonIdMetier == 33) {
                PrintToChat(client, "%s Pas encore fait ! ", "[Rp Magnetik : ->]");
            }
            if (SonIdMetier == 34) {
                PrintToChat(client, "%s Pas encore fait ! ", "[Rp Magnetik : ->]");
            }
            PrintToChat(client, "%s Vous n'avez rien a acheter ! ", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

public BlockAcheterObjets(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new idobjet = StringToInt(parametre, 10);
    new compte = verifieAsseArgent(client, objetPrix[idobjet][0][0]);
    if (compte) {
        new place = TrouverPlaceDansSac(client, idobjet);
        if (0 < place) {
            if (compte == 1) {
                new var1 = clientCash[client];
                var1 = var1[0][0] - objetPrix[idobjet][0][0];
                AjouterArgentCapitalAchats(client, objetPrix[idobjet][0][0]);
                sauvegardeObjetEtCash(client);
                PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", objetPrix[idobjet]);
            } else {
                if (compte == 2) {
                    new var2 = clientBank[client];
                    var2 = var2[0][0] - objetPrix[idobjet][0][0];
                    AjouterArgentCapitalAchats(client, objetPrix[idobjet][0][0]);
                    sauvegardeObjetEtCash(client);
                    PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", objetPrix[idobjet]);
                }
                return 0;
            }
            MettreObjetDansSac(client, place, idobjet);
            sauvegardeObjetEtCash(client);
            OuvirMenuSac(client);
        } else {
            PrintToChat(client, "%s Vous avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockAcheterIkea(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new idobjet = StringToInt(parametre, 10) + -1;
    new compte = verifieAsseArgent(client, listPropPrix[idobjet][0][0]);
    if (compte) {
        if (compte == 1) {
            new var1 = clientCash[client];
            var1 = var1[0][0] - listPropPrix[idobjet][0][0];
            AjouterArgentCapitalAchats(client, listPropPrix[idobjet][0][0]);
            PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", listPropPrix[idobjet]);
            decl Float:eyesOrigin[3];
            decl Float:eyesAngles[3];
            GetClientEyePosition(client, eyesOrigin);
            GetClientEyeAngles(client, eyesAngles);
            decl Float:destinationProp[3];
            new Handle:trace = TR_TraceRayFilterEx(eyesOrigin, eyesAngles, 33570827, RayType:1, TraceEntityFilter:289, client);
            TR_GetEndPosition(destinationProp, trace);
            CloseHandle(trace);
            spawnPropIkea(idobjet, destinationProp);
            sauvegardeObjetEtCash(client);
        } else {
            if (compte == 2) {
                new var2 = clientBank[client];
                var2 = var2[0][0] - listPropPrix[idobjet][0][0];
                AjouterArgentCapitalAchats(client, listPropPrix[idobjet][0][0]);
                PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", listPropPrix[idobjet]);
                decl Float:eyesOrigin[3];
                decl Float:eyesAngles[3];
                GetClientEyePosition(client, eyesOrigin);
                GetClientEyeAngles(client, eyesAngles);
                decl Float:destinationProp[3];
                new Handle:trace = TR_TraceRayFilterEx(eyesOrigin, eyesAngles, 33570827, RayType:1, TraceEntityFilter:289, client);
                TR_GetEndPosition(destinationProp, trace);
                CloseHandle(trace);
                spawnPropIkea(idobjet, destinationProp);
                sauvegardeObjetEtCash(client);
            }
            return 0;
        }
    } else {
        PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockAcheterExplosif(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new idobjet = StringToInt(parametre, 10);
    new compte = verifieAsseArgent(client, objetPrix[idobjet][0][0]);
    if (compte) {
        new place = TrouverPlaceDansSac(client, idobjet);
        if (0 < place) {
            if (compte == 1) {
                new var1 = clientCash[client];
                var1 = var1[0][0] - objetPrix[idobjet][0][0];
                AjouterArgentCapitalAchats(client, objetPrix[idobjet][0][0]);
                PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", objetPrix[idobjet]);
            } else {
                if (compte == 2) {
                    new var2 = clientBank[client];
                    var2 = var2[0][0] - objetPrix[idobjet][0][0];
                    AjouterArgentCapitalAchats(client, objetPrix[idobjet][0][0]);
                    PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", objetPrix[idobjet]);
                }
                return 0;
            }
            MettreObjetDansSac(client, place, idobjet);
            OuvirMenuSac(client);
        } else {
            PrintToChat(client, "%s Vous avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockAcheterMoniteur(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (num == 1) {
        new compte = verifieAsseArgent(client, 2500);
        if (compte) {
            if (clientPermiSec[client][0][0] == true) {
                PrintToChat(client, "%s Vous avez d‚j… le permi de port d'arme secondaire !", "[Rp Magnetik : ->]");
            } else {
                if (compte == 1) {
                    new var1 = clientCash[client];
                    var1 = var1[0][0] + -2500;
                    AjouterArgentCapitalAchats(client, 2500);
                    sauvegardeObjetEtCash(client);
                    clientPermiSec[client] = 1;
                    PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes secondaire !", "[Rp Magnetik : ->]");
                }
                if (compte == 2) {
                    new var2 = clientBank[client];
                    var2 = var2[0][0] + -2500;
                    AjouterArgentCapitalAchats(client, 2500);
                    sauvegardeObjetEtCash(client);
                    clientPermiSec[client] = 1;
                    PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes secondaire !", "[Rp Magnetik : ->]");
                }
                return 0;
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
        }
    } else {
        if (num == 2) {
            new compte = verifieAsseArgent(client, 3500);
            if (compte) {
                if (clientPermiPri[client][0][0] == true) {
                    PrintToChat(client, "%s Vous avez d‚j… le permi de port d'arme primaire !", "[Rp Magnetik : ->]");
                } else {
                    if (compte == 1) {
                        new var3 = clientCash[client];
                        var3 = var3[0][0] + -3500;
                        AjouterArgentCapitalAchats(client, 3500);
                        clientPermiPri[client] = 1;
                        PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes primaire !", "[Rp Magnetik : ->]");
                    }
                    if (compte == 2) {
                        new var4 = clientBank[client];
                        var4 = var4[0][0] + -3500;
                        AjouterArgentCapitalAchats(client, 3500);
                        clientPermiPri[client] = 1;
                        PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes primaire !", "[Rp Magnetik : ->]");
                    }
                    return 0;
                }
            } else {
                PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
            }
        }
        if (num == 3) {
            new Handle:g_MenuAcheterPrecision = CreateMenu(MenuHandler:13, MenuAction:28);
            SetMenuTitle(g_MenuAcheterPrecision, "| Pr‚cision de tir |");
            AddMenuItem(g_MenuAcheterPrecision, "1", "1 Pr‚cision 30$", 0);
            AddMenuItem(g_MenuAcheterPrecision, "2", "2 Pr‚cision 60$", 0);
            AddMenuItem(g_MenuAcheterPrecision, "5", "5 Pr‚cision 150$", 0);
            AddMenuItem(g_MenuAcheterPrecision, "10", "10 Pr‚cision 300$", 0);
            AddMenuItem(g_MenuAcheterPrecision, "20", "20 Pr‚cision 600$", 0);
            AddMenuItem(g_MenuAcheterPrecision, "50", "50 Pr‚cision 1500$", 0);
            AddMenuItem(g_MenuAcheterPrecision, "70", "70 Pr‚cision 2100$", 0);
            AddMenuItem(g_MenuAcheterPrecision, "100", "100 Pr‚cision 3000$", 0);
            DisplayMenu(g_MenuAcheterPrecision, client, 300);
        }
        new compte = verifieAsseArgent(client, objetPrix[num][0][0]);
        if (compte) {
            new place = TrouverPlaceDansSac(client, num);
            if (0 < place) {
                if (compte == 1) {
                    new var5 = clientCash[client];
                    var5 = var5[0][0] - objetPrix[num][0][0];
                    AjouterArgentCapitalAchats(client, objetPrix[num][0][0]);
                    PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", objetPrix[num]);
                } else {
                    if (compte == 2) {
                        new var6 = clientBank[client];
                        var6 = var6[0][0] - objetPrix[num][0][0];
                        AjouterArgentCapitalAchats(client, objetPrix[num][0][0]);
                        PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", objetPrix[num]);
                    }
                    return 0;
                }
                MettreObjetDansSac(client, place, num);
                OuvirMenuSac(client);
            } else {
                PrintToChat(client, "%s Vous avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

public BlockAcheterLevelPrecision(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new num = StringToInt(parametre, 10);
    new compte = verifieAsseArgent(client, num * 30);
    if (compte) {
        new sonLevel = clientPrecision[client][0][0];
        if (num + sonLevel < 101) {
            if (compte == 1) {
                new var1 = clientCash[client];
                var1 = var1[0][0] - num * 30;
                AjouterArgentCapitalAchats(client, num * 30);
                sauvegardeObjetEtCash(client);
                new var2 = clientPrecision[client];
                var2 = var2[0][0] + num;
                PrintToChat(client, "%s Transaction valid‚ ! %d$ on ‚tait retirer de ton portefeuille", "[Rp Magnetik : ->]", num * 30);
                voirMonLevelKnife(client);
            } else {
                if (compte == 2) {
                    new var3 = clientBank[client];
                    var3 = var3[0][0] - num * 30;
                    AjouterArgentCapitalAchats(client, num * 30);
                    sauvegardeObjetEtCash(client);
                    new var4 = clientPrecision[client];
                    var4 = var4[0][0] + num;
                    PrintToChat(client, "%s Transaction valid‚ ! %d$ on ‚tait retirer de ton compte bancaire", "[Rp Magnetik : ->]", num * 30);
                    voirMonLevelKnife(client);
                }
                return 0;
            }
        } else {
            PrintToChat(client, "%s Vous ne pouvez pas d‚passer le level de pr‚cision de 100/100 !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockAcheterBanquier(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (num == 1) {
        new compte = verifieAsseArgent(client, 2500);
        if (compte) {
            if (!clientDepoBank[client][0][0]) {
                if (compte == 1) {
                    new var1 = clientCash[client];
                    var1 = var1[0][0] + -2500;
                    AjouterArgentCapitalAchats(client, 2500);
                    clientDepoBank[client] = 1;
                    sauvegardeObjetEtCash(client);
                    PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", 2500);
                } else {
                    if (compte == 2) {
                        new var2 = clientBank[client];
                        var2 = var2[0][0] + -2500;
                        AjouterArgentCapitalAchats(client, 2500);
                        clientDepoBank[client] = 1;
                        sauvegardeObjetEtCash(client);
                        PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", 2500);
                    }
                    return 0;
                }
            } else {
                PrintToChat(client, "%s Vous pouvez d‚j… d‚poser des objets en banque ! ", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
        }
    } else {
        if (num == 2) {
            new compte = verifieAsseArgent(client, 4500);
            if (compte) {
                if (!clientCarteCredit[client][0][0]) {
                    if (compte == 1) {
                        new var3 = clientCash[client];
                        var3 = var3[0][0] + -4500;
                        AjouterArgentCapitalAchats(client, 4500);
                        clientCarteCredit[client] = 1;
                        PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", 4500);
                    } else {
                        if (compte == 2) {
                            new var4 = clientBank[client];
                            var4 = var4[0][0] + -4500;
                            AjouterArgentCapitalAchats(client, 4500);
                            clientCarteCredit[client] = 1;
                            PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", 4500);
                        }
                        return 0;
                    }
                } else {
                    PrintToChat(client, "%s Vous avez d‚j… une carte bancaire !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
            }
        }
        if (num == 3) {
            new compte = verifieAsseArgent(client, 3500);
            if (compte) {
                if (!clientRibe[client][0][0]) {
                    if (compte == 1) {
                        new var5 = clientCash[client];
                        var5 = var5[0][0] + -3500;
                        AjouterArgentCapitalAchats(client, 3500);
                        clientRibe[client] = 1;
                        PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", 3500);
                    } else {
                        if (compte == 2) {
                            new var6 = clientBank[client];
                            var6 = var6[0][0] + -3500;
                            AjouterArgentCapitalAchats(client, 3500);
                            clientRibe[client] = 1;
                            PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", 3500);
                        }
                        return 0;
                    }
                } else {
                    PrintToChat(client, "%s Vous avez d‚j… un R.I.B ! ", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockAcheterCoutelier(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (num == 1) {
        new Handle:g_MenuAchetLevelknife = CreateMenu(MenuHandler:11, MenuAction:28);
        SetMenuTitle(g_MenuAchetLevelknife, "| Acheter Level knife |");
        AddMenuItem(g_MenuAchetLevelknife, "1", "1 knife 20$", 0);
        AddMenuItem(g_MenuAchetLevelknife, "2", "2 knife 40$", 0);
        AddMenuItem(g_MenuAchetLevelknife, "5", "5 knife 100$", 0);
        AddMenuItem(g_MenuAchetLevelknife, "10", "10 knife 200$", 0);
        AddMenuItem(g_MenuAchetLevelknife, "20", "20 knife 400$", 0);
        AddMenuItem(g_MenuAchetLevelknife, "50", "50 knife 1000$", 0);
        AddMenuItem(g_MenuAchetLevelknife, "70", "70 knife 1400$", 0);
        AddMenuItem(g_MenuAchetLevelknife, "100", "100 knife 2000$", 0);
        DisplayMenu(g_MenuAchetLevelknife, client, 300);
    } else {
        new compte = verifieAsseArgent(client, objetPrix[num][0][0]);
        if (compte) {
            new place = TrouverPlaceDansSac(client, num);
            if (0 < place) {
                if (compte == 1) {
                    new var1 = clientCash[client];
                    var1 = var1[0][0] - objetPrix[num][0][0];
                    AjouterArgentCapitalAchats(client, objetPrix[num][0][0]);
                    sauvegardeObjetEtCash(client);
                    PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", objetPrix[num]);
                } else {
                    if (compte == 2) {
                        new var2 = clientBank[client];
                        var2 = var2[0][0] - objetPrix[num][0][0];
                        AjouterArgentCapitalAchats(client, objetPrix[num][0][0]);
                        sauvegardeObjetEtCash(client);
                        PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", objetPrix[num]);
                    }
                    return 0;
                }
                MettreObjetDansSac(client, place, num);
                OuvirMenuSac(client);
            } else {
                PrintToChat(client, "%s Vous avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

public BlockAcheterLevelKnife(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 6, 0, "", 0);
    new num = StringToInt(parametre, 10);
    new compte = verifieAsseArgent(client, num * 20);
    if (compte) {
        new sonLevel = clientLevelKnife[client][0][0];
        if (num + sonLevel < 101) {
            if (compte == 1) {
                new var1 = clientCash[client];
                var1 = var1[0][0] - num * 20;
                AjouterArgentCapitalAchats(client, num * 20);
                new var2 = clientLevelKnife[client];
                var2 = var2[0][0] + num;
                sauvegardeObjetEtCash(client);
                PrintToChat(client, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                voirMonLevelKnife(client);
            } else {
                if (compte == 2) {
                    new var3 = clientBank[client];
                    var3 = var3[0][0] - num * 20;
                    AjouterArgentCapitalAchats(client, num * 20);
                    new var4 = clientLevelKnife[client];
                    var4 = var4[0][0] + num;
                    sauvegardeObjetEtCash(client);
                    PrintToChat(client, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                    voirMonLevelKnife(client);
                }
                return 0;
            }
        } else {
            PrintToChat(client, "%s Vous ne pouvez pas d‚passer un level knife de 100/100 !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
    }
    return 0;
}

verifieAsseArgent(client, argent)
{
    new cash = clientCash[client][0][0];
    if (cash >= argent) {
        return 1;
    }
    if (clientCarteCredit[client][0][0]) {
        new bank = clientBank[client][0][0];
        if (bank >= argent) {
            return 2;
        }
    }
    return 0;
}

CreationMenuVendre()
{
    decl String:buffer[8];
    decl String:InfoObjet[60];
    g_MenuVendMafiaFrez = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendMafiaFrez, "Vendre des armes:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 35) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendMafiaFrez, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendMafiaItal = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendMafiaItal, "Vendre des armes:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 37) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendMafiaItal, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendMafiaRusse = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendMafiaRusse, "Vendre des armes:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 39) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendMafiaRusse, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendMedic = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendMedic, "Vendre des Medic:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 6) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendMedic, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendPizza = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendPizza, "Vendre une Pizza :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 9) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendPizza, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendMoniteur = CreateMenu(MenuHandler:135, MenuAction:28);
    SetMenuTitle(g_MenuVendMoniteur, "Vente du Moniteur :");
    AddMenuItem(g_MenuVendMoniteur, "1", "Port d'arme secondaire 2500$", 0);
    AddMenuItem(g_MenuVendMoniteur, "2", "Port d'arme primaire 3500$", 0);
    AddMenuItem(g_MenuVendMoniteur, "3", "Pr‚cision de tir 30$/unite", 0);
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 11) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendMoniteur, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendBanque = CreateMenu(MenuHandler:123, MenuAction:28);
    SetMenuTitle(g_MenuVendBanque, "Vente du Banquier :");
    AddMenuItem(g_MenuVendBanque, "1", "D‚po d'objets en banque 2500$", 0);
    AddMenuItem(g_MenuVendBanque, "2", "Carte de credit 4500$", 0);
    AddMenuItem(g_MenuVendBanque, "3", "R.I.B 3500$", 0);
    g_MenuVendSerrurier = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendSerrurier, "| Vente du Serrurier |\nPour renforcer une serrure\nIl faut augmenter par palier N1 -> N2 ->...");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 15) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendSerrurier, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendCoutelier = CreateMenu(MenuHandler:129, MenuAction:28);
    SetMenuTitle(g_MenuVendCoutelier, "Vente du coutelier :");
    AddMenuItem(g_MenuVendCoutelier, "1", "Level knife 20$/unite", 0);
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 17) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendCoutelier, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendArme = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendArme, "Vente une Arme :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 19) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendArme, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendExplosif = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendExplosif, "Vente de l'explosif :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 21) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendExplosif, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendDetective = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendDetective, "Vente du D‚tective :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 23) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendDetective, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendIkea = CreateMenu(MenuHandler:131, MenuAction:28);
    SetMenuTitle(g_MenuVendIkea, "| Vendre des objets d'Ikea |");
    AddMenuItem(g_MenuVendIkea, "1", "Un distributeur 200$", 0);
    AddMenuItem(g_MenuVendIkea, "2", "Un canap‚ 50$", 0);
    AddMenuItem(g_MenuVendIkea, "3", "Une bibliothŠque 100$", 0);
    AddMenuItem(g_MenuVendIkea, "4", "Une machine … laver 35$", 0);
    AddMenuItem(g_MenuVendIkea, "5", "Une gazini‚re 180$", 0);
    AddMenuItem(g_MenuVendIkea, "6", "Une table … manger 150$", 0);
    AddMenuItem(g_MenuVendIkea, "7", "Une chaise 25$", 0);
    AddMenuItem(g_MenuVendIkea, "8", "Un pot de fleur 15$", 0);
    AddMenuItem(g_MenuVendIkea, "9", "Une table en bois 125$", 0);
    AddMenuItem(g_MenuVendIkea, "10", "Un grand placard  200$", 0);
    g_MenuVendBoisson = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendBoisson, "Vente une Boisson :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 27) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendBoisson, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendDrogue = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendDrogue, "Vente de la Drogue :");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 29) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendDrogue, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    g_MenuVendskins = CreateMenu(MenuHandler:137, MenuAction:28);
    SetMenuTitle(g_MenuVendskins, "Vente d'habit:");
    new i = 1;
    while (i < 84) {
        if (objetIdAssoc[i][0][0] == 31) {
            Format(buffer, 8, "%d", i);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i]);
            AddMenuItem(g_MenuVendskins, buffer, InfoObjet, 0);
            i++;
        }
        i++;
    }
    return 0;
}

PlayerStartVendreObjets(client)
{
    new SonIdMetier = clientIdMetier[client][0][0];
    new var1;
    if (SonIdMetier == 6) {
        CancelClientMenu(client, false, Handle:0);
        DisplayMenu(g_MenuVendMedic, client, 300);
    } else {
        new var2;
        if (SonIdMetier == 9) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendPizza, client, 300);
        }
        new var3;
        if (SonIdMetier == 11) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendMoniteur, client, 300);
        }
        new var4;
        if (SonIdMetier == 13) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendBanque, client, 300);
        }
        new var5;
        if (SonIdMetier == 15) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendSerrurier, client, 300);
        }
        new var6;
        if (SonIdMetier == 17) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendCoutelier, client, 300);
        }
        new var7;
        if (SonIdMetier == 19) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendArme, client, 300);
        }
        new var8;
        if (SonIdMetier == 21) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendExplosif, client, 300);
        }
        new var9;
        if (SonIdMetier == 23) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendDetective, client, 300);
        }
        new var10;
        if (SonIdMetier == 25) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendIkea, client, 300);
        }
        new var11;
        if (SonIdMetier == 27) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendBoisson, client, 300);
        }
        new var12;
        if (SonIdMetier == 29) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendDrogue, client, 300);
        }
        new var13;
        if (SonIdMetier == 35) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendMafiaFrez, client, 300);
        }
        new var14;
        if (SonIdMetier == 37) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendMafiaItal, client, 300);
        }
        new var15;
        if (SonIdMetier == 39) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendMafiaRusse, client, 300);
        }
        new var16;
        if (SonIdMetier == 31) {
            CancelClientMenu(client, false, Handle:0);
            DisplayMenu(g_MenuVendskins, client, 300);
        }
        if (SonIdMetier == 33) {
            PrintToChat(client, "%s Pas encore fait ! ", "[Rp Magnetik : ->]");
        }
        if (SonIdMetier == 34) {
            PrintToChat(client, "%s Pas encore fait ! ", "[Rp Magnetik : ->]");
        }
        PrintToChat(client, "%s Vous n'avez rien a vendre ! ", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockVendreMoniteur(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (num == 1) {
        if (viseJoueur(client)) {
            new clientTarget = GetClientAimTarget(client, true);
            decl String:steamTarget[32];
            GetClientAuthString(clientTarget, steamTarget, 32);
            decl String:nameTarget[32];
            GetClientName(clientTarget, nameTarget, 32);
            new Handle:g_MenuConfirPermiSecondaire = CreateMenu(MenuHandler:139, MenuAction:28);
            decl String:titre[128];
            Format(titre, 128, "| Confirmation Vendre |\n Port d'arme secondaire\nA %s", nameTarget);
            SetMenuTitle(g_MenuConfirPermiSecondaire, titre);
            decl String:buffer[128];
            Format(buffer, 128, "1,%s,%d,2", steamTarget, clientTarget);
            AddMenuItem(g_MenuConfirPermiSecondaire, buffer, "-> Accepter", 0);
            Format(buffer, 128, "2,%s,%d,2", steamTarget, clientTarget);
            AddMenuItem(g_MenuConfirPermiSecondaire, buffer, "-> Refuser", 0);
            DisplayMenu(g_MenuConfirPermiSecondaire, client, 300);
        } else {
            PrintToChat(client, "%s Tu n'as pas vis‚ quelqun ou tu es trop loin !", "[Rp Magnetik : ->]");
        }
    } else {
        if (num == 2) {
            if (viseJoueur(client)) {
                new clientTarget = GetClientAimTarget(client, true);
                decl String:steamTarget[32];
                GetClientAuthString(clientTarget, steamTarget, 32);
                decl String:nameTarget[32];
                GetClientName(clientTarget, nameTarget, 32);
                new Handle:g_MenuConfirPermiSecondaire = CreateMenu(MenuHandler:139, MenuAction:28);
                decl String:titres[128];
                Format(titres, 128, "| Confirmation Vendre |\n Port d'arme primaire\nA %s", nameTarget);
                SetMenuTitle(g_MenuConfirPermiSecondaire, titres);
                decl String:buff[128];
                Format(buff, 128, "1,%s,%d,1", steamTarget, clientTarget);
                AddMenuItem(g_MenuConfirPermiSecondaire, buff, "-> Accepter", 0);
                Format(buff, 128, "2,%s,%d,1", steamTarget, clientTarget);
                AddMenuItem(g_MenuConfirPermiSecondaire, buff, "-> Refuser", 0);
                DisplayMenu(g_MenuConfirPermiSecondaire, client, 300);
            } else {
                PrintToChat(client, "%s Tu n'as pas vis‚ quelqun ou tu es trop loin !", "[Rp Magnetik : ->]");
            }
        }
        if (num == 3) {
            new Handle:g_MenuVendrePrecision = CreateMenu(MenuHandler:133, MenuAction:28);
            SetMenuTitle(g_MenuVendrePrecision, "| Pr‚cision de tir |");
            AddMenuItem(g_MenuVendrePrecision, "1", "1 Pr‚cision 30$", 0);
            AddMenuItem(g_MenuVendrePrecision, "2", "2 Pr‚cision 60$", 0);
            AddMenuItem(g_MenuVendrePrecision, "5", "5 Pr‚cision 150$", 0);
            AddMenuItem(g_MenuVendrePrecision, "10", "10 Pr‚cision 300$", 0);
            AddMenuItem(g_MenuVendrePrecision, "20", "20 Pr‚cision 600$", 0);
            AddMenuItem(g_MenuVendrePrecision, "50", "50 Pr‚cision 1500$", 0);
            AddMenuItem(g_MenuVendrePrecision, "70", "70 Pr‚cision 2100$", 0);
            AddMenuItem(g_MenuVendrePrecision, "100", "100 Pr‚cision 3000$", 0);
            DisplayMenu(g_MenuVendrePrecision, client, 300);
        }
        decl String:titre[60];
        new Handle:g_MenuAutantDobjet = CreateMenu(MenuHandler:121, MenuAction:28);
        Format(titre, 60, "| Combien de : %s |\nVoulez-vous vendre ?", objetNom[num][0][0]);
        SetMenuTitle(g_MenuAutantDobjet, titre);
        decl String:para[40];
        decl String:buffer[60];
        Format(para, 40, "1,%d", num);
        Format(buffer, 60, "Nbr 1 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "2,%d", num);
        Format(buffer, 60, "Nbr 2 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "5,%d", num);
        Format(buffer, 60, "Nbr 5 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "10,%d", num);
        Format(buffer, 60, "Nbr 10 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "20,%d", num);
        Format(buffer, 60, "Nbr 20 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "50,%d", num);
        Format(buffer, 60, "Nbr 50 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        DisplayMenu(g_MenuAutantDobjet, client, 300);
    }
    return 0;
}

public BlockVendreLevelPrecision(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 6, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (viseJoueur(client)) {
        new clientTarget = GetClientAimTarget(client, true);
        decl String:steamTarget[32];
        GetClientAuthString(clientTarget, steamTarget, 32);
        decl String:nameTarget[32];
        GetClientName(clientTarget, nameTarget, 32);
        new Handle:g_MenuConfirLeveltir = CreateMenu(MenuHandler:127, MenuAction:28);
        decl String:titre[128];
        Format(titre, 128, "| Confirmation Vendre |\n %d Level de Pr‚cision\nPrix : %d $\nA %s", num, num * 30, nameTarget);
        SetMenuTitle(g_MenuConfirLeveltir, titre);
        decl String:buffer[128];
        Format(buffer, 128, "1,%s,%d,%d", steamTarget, clientTarget, num);
        AddMenuItem(g_MenuConfirLeveltir, buffer, "-> Accepter", 0);
        Format(buffer, 128, "2,%s,%d,%d", steamTarget, clientTarget, num);
        AddMenuItem(g_MenuConfirLeveltir, buffer, "-> Refuser", 0);
        DisplayMenu(g_MenuConfirLeveltir, client, 300);
    } else {
        PrintToChat(client, "%s Tu n'as pas vis‚ quelqun ou tu es trop loin !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockVendreConfirLevelTir(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    new valeur = StringToInt(split[0][split], 10);
    new clientTarget = StringToInt(split[8], 10);
    new num = StringToInt(split[12], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientTarget)) {
            decl String:steamTarget[32];
            GetClientAuthString(clientTarget, steamTarget, 32);
            new var2;
            if (StrEqual(steamTarget, split[4], true)) {
                if (posDeuxJoueur(client, clientTarget)) {
                    decl String:steamVend[32];
                    GetClientAuthString(client, steamVend, 32);
                    new Handle:g_MenuValidVendreTir = CreateMenu(MenuHandler:145, MenuAction:28);
                    decl String:titre[256];
                    Format(titre, 256, "Voulez vous Acheter ?\n %d Level Pr‚cision\n Prix : %d $", num, num * 30);
                    SetMenuTitle(g_MenuValidVendreTir, titre);
                    decl String:buffer[128];
                    Format(buffer, 128, "1,%s,%d,%d", steamVend, client, num);
                    AddMenuItem(g_MenuValidVendreTir, buffer, "-> Accepter", 0);
                    Format(buffer, 128, "2,%s,%d,%d", steamVend, client, num);
                    AddMenuItem(g_MenuValidVendreTir, buffer, "-> Refuser", 0);
                    DisplayMenu(g_MenuValidVendreTir, clientTarget, 300);
                    PrintToChat(client, "%s Veuillez patienter pendant que le client accepte ou refuse sa commande !", "[Rp Magnetik : ->]");
                } else {
                    PrintToChat(client, "%s Votre client est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Votre client est parti !", "[Rp Magnetik : ->]");
            }
        }
        PrintToChat(client, "%s Votre client est parti !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockVendreValidPreciTir(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    new valeur = StringToInt(split[0][split], 10);
    new clientVend = StringToInt(split[8], 10);
    new num = StringToInt(split[12], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientVend)) {
            decl String:steamVend[32];
            GetClientAuthString(clientVend, steamVend, 32);
            new var2;
            if (StrEqual(steamVend, split[4], true)) {
                if (posDeuxJoueur(client, clientVend)) {
                    new compte = verifieAsseArgent(client, num * 30);
                    if (compte) {
                        new sonLevel = clientPrecision[client][0][0];
                        if (num + sonLevel < 101) {
                            if (compte == 1) {
                                AjouterArgentCapitalAchats(clientVend, num * 30);
                                new var5 = clientCash[client];
                                var5 = var5[0][0] - num * 30;
                                new var6 = clientPrecision[client];
                                var6 = var6[0][0] + num;
                                sauvegardeObjetEtCash(client);
                                sauvegardeObjetEtCash(clientVend);
                                PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                voirMonLevelKnife(client);
                            } else {
                                if (compte == 2) {
                                    AjouterArgentCapitalAchats(clientVend, num * 30);
                                    new var7 = clientBank[client];
                                    var7 = var7[0][0] - num * 30;
                                    new var8 = clientPrecision[client];
                                    var8 = var8[0][0] + num;
                                    sauvegardeObjetEtCash(client);
                                    sauvegardeObjetEtCash(clientVend);
                                    PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                    voirMonLevelKnife(client);
                                }
                            }
                        } else {
                            PrintToChat(client, "%s Vous ne pouvez pas d‚passer un level de pr‚cision de 100/100 !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Le vendeur est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        new var3;
        if (IsClientInGame(clientVend)) {
            decl String:steamVend[32];
            GetClientAuthString(clientVend, steamVend, 32);
            new var4;
            if (StrEqual(steamVend, split[4], true)) {
                PrintToChat(clientVend, "%s Votre client a refuser !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockVendrePermi(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    new valeur = StringToInt(split[0][split], 10);
    new clientTarget = StringToInt(split[8], 10);
    new permi = StringToInt(split[12], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientTarget)) {
            decl String:steamTarget[32];
            GetClientAuthString(clientTarget, steamTarget, 32);
            new var2;
            if (StrEqual(steamTarget, split[4], true)) {
                if (posDeuxJoueur(client, clientTarget)) {
                    decl String:steamVend[32];
                    GetClientAuthString(client, steamVend, 32);
                    new Handle:g_MenuValidPermi = CreateMenu(MenuHandler:147, MenuAction:28);
                    decl String:titre[256];
                    if (permi == 1) {
                        Format(titre, 256, "Voulez-vous Acheter ?\n Port d'arme primaire\n prix : 3500$");
                    } else {
                        Format(titre, 256, "Voulez-vous Acheter ?\n Port d'arme secondaire\n prix : 2500$");
                    }
                    SetMenuTitle(g_MenuValidPermi, titre);
                    decl String:buffer[128];
                    if (permi == 1) {
                        Format(buffer, 128, "1,%s,%d,1", steamVend, client);
                        AddMenuItem(g_MenuValidPermi, buffer, "-> Accepter", 0);
                        Format(buffer, 128, "2,%s,%d,1", steamVend, client);
                        AddMenuItem(g_MenuValidPermi, buffer, "-> Refuser", 0);
                    } else {
                        Format(buffer, 128, "1,%s,%d,2", steamVend, client);
                        AddMenuItem(g_MenuValidPermi, buffer, "-> Accepter", 0);
                        Format(buffer, 128, "2,%s,%d,2", steamVend, client);
                        AddMenuItem(g_MenuValidPermi, buffer, "-> Refuser", 0);
                    }
                    DisplayMenu(g_MenuValidPermi, clientTarget, 300);
                    PrintToChat(client, "%s Veuillez patienter pendant que le client accepte ou refuse sa commande !", "[Rp Magnetik : ->]");
                } else {
                    PrintToChat(client, "%s Votre client est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Votre client est partie !", "[Rp Magnetik : ->]");
            }
        }
        PrintToChat(client, "%s Votre client est partie !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockVendreValidePermie(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    new valeur = StringToInt(split[0][split], 10);
    new clientVend = StringToInt(split[8], 10);
    new permi = StringToInt(split[12], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientVend)) {
            decl String:steamVend[32];
            GetClientAuthString(clientVend, steamVend, 32);
            new var2;
            if (StrEqual(steamVend, split[4], true)) {
                if (posDeuxJoueur(client, clientVend)) {
                    if (permi == 1) {
                        if (clientPermiPri[client][0][0] == true) {
                            PrintToChat(clientVend, "%s Votre client a d‚j… son permi de port d'arme primaire !", "[Rp Magnetik : ->]");
                            PrintToChat(client, "%s Vous avez d‚j… le permi de port d'arme primaire !", "[Rp Magnetik : ->]");
                        } else {
                            new compte = verifieAsseArgent(client, 3500);
                            if (compte) {
                                if (compte == 1) {
                                    AjouterArgentCapitalAchats(clientVend, 3500);
                                    new var5 = clientCash[client];
                                    var5 = var5[0][0] + -3500;
                                    clientPermiPri[client] = 1;
                                    PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes primaire !", "[Rp Magnetik : ->]");
                                    PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                } else {
                                    if (compte == 2) {
                                        AjouterArgentCapitalAchats(clientVend, 3500);
                                        new var6 = clientBank[client];
                                        var6 = var6[0][0] + -3500;
                                        clientPermiPri[client] = 1;
                                        PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes primaire !", "[Rp Magnetik : ->]");
                                        PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                    }
                                    return 0;
                                }
                            } else {
                                PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                            }
                        }
                    } else {
                        if (clientPermiSec[client][0][0] == true) {
                            PrintToChat(clientVend, "%s Votre client a d‚j… son permi de port d'arme secondaire !", "[Rp Magnetik : ->]");
                            PrintToChat(client, "%s Vous avez d‚j… le permi de port d'arme secondaire !", "[Rp Magnetik : ->]");
                        }
                        new compte = verifieAsseArgent(client, 2500);
                        if (compte) {
                            if (compte == 1) {
                                AjouterArgentCapitalAchats(clientVend, 2500);
                                new var7 = clientCash[client];
                                var7 = var7[0][0] + -2500;
                                clientPermiSec[client] = 1;
                                PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes secondaire !", "[Rp Magnetik : ->]");
                                PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                            } else {
                                if (compte == 2) {
                                    AjouterArgentCapitalAchats(clientVend, 2500);
                                    new var8 = clientBank[client];
                                    var8 = var8[0][0] + -2500;
                                    clientPermiSec[client] = 1;
                                    PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes secondaire !", "[Rp Magnetik : ->]");
                                    PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                        }
                    }
                } else {
                    PrintToChat(client, "%s Le vendeur est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        new var3;
        if (IsClientInGame(clientVend)) {
            decl String:steamVend[32];
            GetClientAuthString(clientVend, steamVend, 32);
            new var4;
            if (StrEqual(steamVend, split[4], true)) {
                PrintToChat(clientVend, "%s Votre client a refuser !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockVendreIkea(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new num = StringToInt(parametre, 10) + -1;
    if (viseJoueur(client)) {
        new clientTarget = GetClientAimTarget(client, true);
        decl String:steamID[32];
        GetClientAuthString(client, steamID, 32);
        new Handle:g_MenuValidIkea = CreateMenu(MenuHandler:117, MenuAction:28);
        decl String:titre[256];
        Format(titre, 256, "Voulez-vous acheter %s \n Prix : %d $", listPropNom[num][0][0], listPropPrix[num]);
        SetMenuTitle(g_MenuValidIkea, titre);
        decl String:buffer[64];
        Format(buffer, 64, "1,%s,%d,%d", steamID, client, num);
        AddMenuItem(g_MenuValidIkea, buffer, "-> Accepter", 0);
        Format(buffer, 64, "2,%s,%d,%d", steamID, client, num);
        AddMenuItem(g_MenuValidIkea, buffer, "-> Refuser", 0);
        DisplayMenu(g_MenuValidIkea, clientTarget, 300);
        PrintToChat(client, "%s Veuillez patienter pendant que le client accepte ou refuse sa commande !", "[Rp Magnetik : ->]");
    } else {
        PrintToChat(client, "%s Tu n'as pas vis‚ quelqu'un ou tu es trop loin !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockValidIkea(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[64];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 64, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    decl String:SteamVend[32];
    new valeur = StringToInt(split[0][split], 10);
    Format(SteamVend, 32, "%s", split[4]);
    new clientVend = StringToInt(split[8], 10);
    new idobjet = StringToInt(split[12], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                if (posDeuxJoueur(client, clientVend)) {
                    new compte = verifieAsseArgent(client, listPropPrix[idobjet][0][0]);
                    if (compte) {
                        if (compte == 1) {
                            AjouterArgentCapitalAchats(clientVend, listPropPrix[idobjet][0][0]);
                            new var3 = clientCash[client];
                            var3 = var3[0][0] - listPropPrix[idobjet][0][0];
                            PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                            decl Float:eyesOrigin[3];
                            decl Float:eyesAngles[3];
                            GetClientEyePosition(client, eyesOrigin);
                            GetClientEyeAngles(client, eyesAngles);
                            decl Float:destinationProp[3];
                            new Handle:trace = TR_TraceRayFilterEx(eyesOrigin, eyesAngles, 33570827, RayType:1, TraceEntityFilter:289, client);
                            TR_GetEndPosition(destinationProp, trace);
                            CloseHandle(trace);
                            spawnPropIkea(idobjet, destinationProp);
                        } else {
                            if (compte == 2) {
                                AjouterArgentCapitalAchats(clientVend, listPropPrix[idobjet][0][0]);
                                new var4 = clientBank[client];
                                var4 = var4[0][0] - listPropPrix[idobjet][0][0];
                                PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                decl Float:eyesOrigin[3];
                                decl Float:eyesAngles[3];
                                GetClientEyePosition(client, eyesOrigin);
                                GetClientEyeAngles(client, eyesAngles);
                                decl Float:destinationProp[3];
                                new Handle:trace = TR_TraceRayFilterEx(eyesOrigin, eyesAngles, 33570827, RayType:1, TraceEntityFilter:289, client);
                                TR_GetEndPosition(destinationProp, trace);
                                CloseHandle(trace);
                                spawnPropIkea(idobjet, destinationProp);
                            }
                            return 0;
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Le vendeur est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        new var2;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                PrintToChat(clientVend, "%s Votre client a refuser !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockVendreBanquier(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (num == 1) {
        if (viseJoueur(client)) {
            new clientTarget = GetClientAimTarget(client, true);
            decl String:steamID[32];
            GetClientAuthString(client, steamID, 32);
            new Handle:g_MenuValidDepo = CreateMenu(MenuHandler:115, MenuAction:28);
            decl String:titre[256];
            Format(titre, 256, "Voulez-vous avoir la possibilit‚\nde d‚poser vos objets en banque ?\n Prix : 2500$");
            SetMenuTitle(g_MenuValidDepo, titre);
            decl String:buffer[64];
            Format(buffer, 64, "1,%s,%d", steamID, client);
            AddMenuItem(g_MenuValidDepo, buffer, "-> Accepter", 0);
            Format(buffer, 64, "2,%s,%d", steamID, client);
            AddMenuItem(g_MenuValidDepo, buffer, "-> Refuser", 0);
            DisplayMenu(g_MenuValidDepo, clientTarget, 300);
            PrintToChat(client, "%s Veuillez patienter pendant que le client accepte ou refuse sa commande !", "[Rp Magnetik : ->]");
        } else {
            PrintToChat(client, "%s Tu n'as pas vis‚ quelqu'un ou tu es trop loin !", "[Rp Magnetik : ->]");
        }
    } else {
        if (num == 2) {
            if (viseJoueur(client)) {
                new clientTarget = GetClientAimTarget(client, true);
                decl String:steamID[32];
                GetClientAuthString(client, steamID, 32);
                new Handle:g_MenuValidCarte = CreateMenu(MenuHandler:113, MenuAction:28);
                decl String:titre[256];
                Format(titre, 256, "Voulez-vous une carte de Cr‚dit ?\n Prix : 4500$");
                SetMenuTitle(g_MenuValidCarte, titre);
                decl String:buffer[64];
                Format(buffer, 64, "1,%s,%d", steamID, client);
                AddMenuItem(g_MenuValidCarte, buffer, "-> Accepter", 0);
                Format(buffer, 64, "2,%s,%d", steamID, client);
                AddMenuItem(g_MenuValidCarte, buffer, "-> Refuser", 0);
                DisplayMenu(g_MenuValidCarte, clientTarget, 300);
                PrintToChat(client, "%s Veuillez patienter pendant que le client accepte ou refuse sa commande !", "[Rp Magnetik : ->]");
            } else {
                PrintToChat(client, "%s Tu n'as pas vis‚ quelqu'un ou tu es trop loin !", "[Rp Magnetik : ->]");
            }
        }
        if (num == 3) {
            if (viseJoueur(client)) {
                new clientTarget = GetClientAimTarget(client, true);
                decl String:steamID[32];
                GetClientAuthString(client, steamID, 32);
                new Handle:g_MenuValidRIB = CreateMenu(MenuHandler:119, MenuAction:28);
                decl String:titre[256];
                Format(titre, 256, "Voulez-vous obtenir un RIB ?\n Prix : 3500$");
                SetMenuTitle(g_MenuValidRIB, titre);
                decl String:buffer[64];
                Format(buffer, 64, "1,%s,%d", steamID, client);
                AddMenuItem(g_MenuValidRIB, buffer, "-> Accepter", 0);
                Format(buffer, 64, "2,%s,%d", steamID, client);
                AddMenuItem(g_MenuValidRIB, buffer, "-> Refuser", 0);
                DisplayMenu(g_MenuValidRIB, clientTarget, 300);
                PrintToChat(client, "%s Veuillez patienter pendant que le client accepte ou refuse sa commande !", "[Rp Magnetik : ->]");
            }
            PrintToChat(client, "%s Tu n'as pas vis‚ quelqu'un ou tu es trop loin !", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

public BlockValidDepoBank(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[60];
    decl String:split[16][32];
    GetMenuItem(menu, choice, parametre, 60, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 32);
    decl String:SteamVend[32];
    new valeur = StringToInt(split[0][split], 10);
    Format(SteamVend, 32, "%s", split[4]);
    new clientVend = StringToInt(split[8], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                if (posDeuxJoueur(client, clientVend)) {
                    new compte = verifieAsseArgent(client, 2500);
                    if (compte) {
                        if (!clientDepoBank[client][0][0]) {
                            if (compte == 1) {
                                AjouterArgentCapitalAchats(clientVend, 2500);
                                new var3 = clientCash[client];
                                var3 = var3[0][0] + -2500;
                                clientDepoBank[client] = 1;
                                PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                            } else {
                                if (compte == 2) {
                                    AjouterArgentCapitalAchats(clientVend, 2500);
                                    new var4 = clientBank[client];
                                    var4 = var4[0][0] + -2500;
                                    clientDepoBank[client] = 1;
                                    PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous disposez d‚j… du d‚pot d'objets en banque !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Le vendeur est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        new var2;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                PrintToChat(clientVend, "%s Votre client a refuser !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockValidCarteCredit(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[60];
    decl String:split[16][32];
    GetMenuItem(menu, choice, parametre, 60, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 32);
    decl String:SteamVend[32];
    new valeur = StringToInt(split[0][split], 10);
    Format(SteamVend, 32, "%s", split[4]);
    new clientVend = StringToInt(split[8], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                if (posDeuxJoueur(client, clientVend)) {
                    new compte = verifieAsseArgent(client, 4500);
                    if (compte) {
                        if (!clientCarteCredit[client][0][0]) {
                            if (compte == 1) {
                                AjouterArgentCapitalAchats(clientVend, 4500);
                                new var3 = clientCash[client];
                                var3 = var3[0][0] + -4500;
                                clientCarteCredit[client] = 1;
                                PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                PrintToChat(client, "%s F‚licitation vous avez une carte bleu Visa !", "[Rp Magnetik : ->]");
                            } else {
                                if (compte == 2) {
                                    AjouterArgentCapitalAchats(clientVend, 4500);
                                    new var4 = clientBank[client];
                                    var4 = var4[0][0] + -4500;
                                    clientCarteCredit[client] = 1;
                                    PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                    PrintToChat(client, "%s F‚licitation vous avez une carte bleu Visa !", "[Rp Magnetik : ->]");
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous disposez d‚j… de la carte de cr‚dit !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Le vendeur est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        new var2;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                PrintToChat(clientVend, "%s Votre client a refuser !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockValidRIB(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[60];
    decl String:split[16][32];
    GetMenuItem(menu, choice, parametre, 60, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 32);
    decl String:SteamVend[32];
    new valeur = StringToInt(split[0][split], 10);
    Format(SteamVend, 32, "%s", split[4]);
    new clientVend = StringToInt(split[8], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                if (posDeuxJoueur(client, clientVend)) {
                    new compte = verifieAsseArgent(client, 3500);
                    if (compte) {
                        if (!clientRibe[client][0][0]) {
                            if (compte == 1) {
                                AjouterArgentCapitalAchats(clientVend, 3500);
                                new var3 = clientCash[client];
                                var3 = var3[0][0] + -3500;
                                clientRibe[client] = 1;
                                PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                PrintToChat(client, "%s F‚licitation vous allez avoir votre salaire sur votre compte !", "[Rp Magnetik : ->]");
                            } else {
                                if (compte == 2) {
                                    AjouterArgentCapitalAchats(clientVend, 3500);
                                    new var4 = clientBank[client];
                                    var4 = var4[0][0] + -3500;
                                    clientRibe[client] = 1;
                                    PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                    PrintToChat(client, "%s F‚licitation vous allez avoir votre salaire sur votre compte !", "[Rp Magnetik : ->]");
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous disposez d‚j… de la carte de cr‚dit !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Le vendeur est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        new var2;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                PrintToChat(clientVend, "%s Votre client a refuser !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockVendreCoutelier(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (num == 1) {
        new Handle:g_MenuVentLevelknife = CreateMenu(MenuHandler:149, MenuAction:28);
        SetMenuTitle(g_MenuVentLevelknife, "| Acheter Level knife |");
        AddMenuItem(g_MenuVentLevelknife, "1", "1 knife 20$", 0);
        AddMenuItem(g_MenuVentLevelknife, "2", "2 knife 40$", 0);
        AddMenuItem(g_MenuVentLevelknife, "5", "5 knife 100$", 0);
        AddMenuItem(g_MenuVentLevelknife, "10", "10 knife 200$", 0);
        AddMenuItem(g_MenuVentLevelknife, "20", "20 knife 400$", 0);
        AddMenuItem(g_MenuVentLevelknife, "50", "50 knife 1000$", 0);
        AddMenuItem(g_MenuVentLevelknife, "70", "70 knife 1400$", 0);
        AddMenuItem(g_MenuVentLevelknife, "100", "100 knife 2000$", 0);
        DisplayMenu(g_MenuVentLevelknife, client, 300);
    } else {
        decl String:titre[60];
        new Handle:g_MenuAutantDobjet = CreateMenu(MenuHandler:121, MenuAction:28);
        Format(titre, 60, "| Combien de : %s |\nVoulez-vous vendre ?", objetNom[num][0][0]);
        SetMenuTitle(g_MenuAutantDobjet, titre);
        decl String:para[40];
        decl String:buffer[60];
        Format(para, 40, "1,%d", num);
        Format(buffer, 60, "Nbr 1 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "2,%d", num);
        Format(buffer, 60, "Nbr 2 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "5,%d", num);
        Format(buffer, 60, "Nbr 5 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "10,%d", num);
        Format(buffer, 60, "Nbr 10 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "20,%d", num);
        Format(buffer, 60, "Nbr 20 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        Format(para, 40, "50,%d", num);
        Format(buffer, 60, "Nbr 50 : %s", objetNom[num][0][0]);
        AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
        DisplayMenu(g_MenuAutantDobjet, client, 300);
    }
    return 0;
}

public BlockVendrelevelKnife(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 6, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (viseJoueur(client)) {
        new clientTarget = GetClientAimTarget(client, true);
        decl String:steamTarget[32];
        GetClientAuthString(clientTarget, steamTarget, 32);
        decl String:nameTarget[32];
        GetClientName(clientTarget, nameTarget, 32);
        new Handle:g_MenuConfirLevelKnife = CreateMenu(MenuHandler:125, MenuAction:28);
        decl String:titre[128];
        Format(titre, 128, "| Confirmation Vendre |\n %d Level Knife\nPrix : %d $\nA %s", num, num * 20, nameTarget);
        SetMenuTitle(g_MenuConfirLevelKnife, titre);
        decl String:buffer[128];
        Format(buffer, 128, "1,%s,%d,%d", steamTarget, clientTarget, num);
        AddMenuItem(g_MenuConfirLevelKnife, buffer, "-> Accepter", 0);
        Format(buffer, 128, "2,%s,%d,%d", steamTarget, clientTarget, num);
        AddMenuItem(g_MenuConfirLevelKnife, buffer, "-> Refuser", 0);
        DisplayMenu(g_MenuConfirLevelKnife, client, 300);
    } else {
        PrintToChat(client, "%s Tu n'as pas vis‚ quelqun ou tu es trop loin !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockVendreConfirLevelKnife(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    new valeur = StringToInt(split[0][split], 10);
    new clientTarget = StringToInt(split[8], 10);
    new num = StringToInt(split[12], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientTarget)) {
            decl String:steamTarget[32];
            GetClientAuthString(clientTarget, steamTarget, 32);
            new var2;
            if (StrEqual(steamTarget, split[4], true)) {
                if (posDeuxJoueur(client, clientTarget)) {
                    decl String:steamVend[32];
                    GetClientAuthString(client, steamVend, 32);
                    new Handle:g_MenuValidVendreKnife = CreateMenu(MenuHandler:141, MenuAction:28);
                    decl String:titre[256];
                    Format(titre, 256, "Voulez vous Acheter ?\n %d Level Knife\n Prix : %d $", num, num * 20);
                    SetMenuTitle(g_MenuValidVendreKnife, titre);
                    decl String:buffer[128];
                    Format(buffer, 128, "1,%s,%d,%d", steamVend, client, num);
                    AddMenuItem(g_MenuValidVendreKnife, buffer, "-> Accepter", 0);
                    Format(buffer, 128, "2,%s,%d,%d", steamVend, client, num);
                    AddMenuItem(g_MenuValidVendreKnife, buffer, "-> Refuser", 0);
                    DisplayMenu(g_MenuValidVendreKnife, clientTarget, 300);
                    PrintToChat(client, "%s Veuillez patienter pendant que le client accepte ou refuse sa commande !", "[Rp Magnetik : ->]");
                } else {
                    PrintToChat(client, "%s Votre client est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Votre client est partie !", "[Rp Magnetik : ->]");
            }
        }
        PrintToChat(client, "%s Votre client est partie !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockVendreValidKnife(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    new valeur = StringToInt(split[0][split], 10);
    new clientVend = StringToInt(split[8], 10);
    new num = StringToInt(split[12], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientVend)) {
            decl String:steamVend[32];
            GetClientAuthString(clientVend, steamVend, 32);
            new var2;
            if (StrEqual(steamVend, split[4], true)) {
                if (posDeuxJoueur(client, clientVend)) {
                    new compte = verifieAsseArgent(client, num * 20);
                    if (compte) {
                        new sonLevel = clientLevelKnife[client][0][0];
                        if (num + sonLevel < 101) {
                            if (compte == 1) {
                                AjouterArgentCapitalAchats(clientVend, num * 20);
                                new var5 = clientCash[client];
                                var5 = var5[0][0] - num * 20;
                                new var6 = clientLevelKnife[client];
                                var6 = var6[0][0] + num;
                                PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                voirMonLevelKnife(client);
                            } else {
                                if (compte == 2) {
                                    AjouterArgentCapitalAchats(clientVend, num * 20);
                                    new var7 = clientBank[client];
                                    var7 = var7[0][0] - num * 20;
                                    new var8 = clientLevelKnife[client];
                                    var8 = var8[0][0] + num;
                                    PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                    voirMonLevelKnife(client);
                                }
                            }
                        } else {
                            PrintToChat(client, "%s Vous ne pouvez pas d‚passer un level knife de 100/100 !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Le vendeur est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        new var3;
        if (IsClientInGame(clientVend)) {
            decl String:steamVend[32];
            GetClientAuthString(clientVend, steamVend, 32);
            new var4;
            if (StrEqual(steamVend, split[4], true)) {
                PrintToChat(clientVend, "%s Votre client a refuser !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

public BlockVendreObjets(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[12];
    GetMenuItem(menu, choice, parametre, 10, 0, "", 0);
    new idObjet = StringToInt(parametre, 10);
    decl String:titre[60];
    new Handle:g_MenuAutantDobjet = CreateMenu(MenuHandler:121, MenuAction:28);
    Format(titre, 60, "| Combien de : %s |\nVoulez-vous vendre ?", objetNom[idObjet][0][0]);
    SetMenuTitle(g_MenuAutantDobjet, titre);
    decl String:para[40];
    decl String:buffer[60];
    Format(para, 40, "1,%d", idObjet);
    Format(buffer, 60, "Nbr 1 : %s", objetNom[idObjet][0][0]);
    AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
    Format(para, 40, "2,%d", idObjet);
    Format(buffer, 60, "Nbr 2 : %s", objetNom[idObjet][0][0]);
    AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
    Format(para, 40, "5,%d", idObjet);
    Format(buffer, 60, "Nbr 5 : %s", objetNom[idObjet][0][0]);
    AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
    Format(para, 40, "10,%d", idObjet);
    Format(buffer, 60, "Nbr 10 : %s", objetNom[idObjet][0][0]);
    AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
    Format(para, 40, "20,%d", idObjet);
    Format(buffer, 60, "Nbr 20 : %s", objetNom[idObjet][0][0]);
    AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
    Format(para, 40, "50,%d", idObjet);
    Format(buffer, 60, "Nbr 50 : %s", objetNom[idObjet][0][0]);
    AddMenuItem(g_MenuAutantDobjet, para, buffer, 0);
    DisplayMenu(g_MenuAutantDobjet, client, 300);
    return 0;
}

public BlockVendreAutantDobjet(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[12];
    decl String:split[12][8];
    GetMenuItem(menu, choice, parametre, 10, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 5);
    new nombre = StringToInt(split[0][split], 10);
    new idObjet = StringToInt(split[4], 10);
    if (viseJoueur(client)) {
        new clientTarget = GetClientAimTarget(client, true);
        decl String:steamId[32];
        GetClientAuthString(client, steamId, 32);
        new Handle:g_MenuValidObjets = CreateMenu(MenuHandler:143, MenuAction:28);
        decl String:titre[256];
        Format(titre, 256, "Voulez vous Acheter ?\n%d %s a %d $\nEffet %d : %s", nombre, objetNom[idObjet][0][0], nombre * objetPrix[idObjet][0][0], objetEffet[idObjet], objetFonction[idObjet][0][0]);
        SetMenuTitle(g_MenuValidObjets, titre);
        decl String:buffer[128];
        Format(buffer, 128, "1,%s,%d,%d,%d", steamId, client, idObjet, nombre);
        AddMenuItem(g_MenuValidObjets, buffer, "-> Accepter", 0);
        Format(buffer, 128, "2,%s,%d,%d,%d", steamId, client, idObjet, nombre);
        AddMenuItem(g_MenuValidObjets, buffer, "-> Refuser", 0);
        DisplayMenu(g_MenuValidObjets, clientTarget, 300);
        PrintToChat(client, "%s Veuillez patienter pendant que le client accepte ou refuse sa commande !", "[Rp Magnetik : ->]");
    } else {
        PrintToChat(client, "%s Tu n'as pas vis‚ quelqun ou tu es trop loin !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockVendreValidObjets(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[24][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 6, 32);
    decl String:SteamVend[32];
    new valeur = StringToInt(split[0][split], 10);
    Format(SteamVend, 32, "%s", split[4]);
    new clientVend = StringToInt(split[8], 10);
    new idObjet = StringToInt(split[12], 10);
    new nbr = StringToInt(split[16], 10);
    if (valeur == 1) {
        new var1;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                if (posDeuxJoueur(client, clientVend)) {
                    new compte = verifieAsseArgent(client, nbr * objetPrix[idObjet][0][0]);
                    if (compte) {
                        new place = TrouverPlaceDansSacNB(client, idObjet, nbr);
                        if (0 < place) {
                            if (compte == 1) {
                                AjouterArgentCapitalAchats(clientVend, nbr * objetPrix[idObjet][0][0]);
                                new var3 = clientCash[client];
                                var3 = var3[0][0] - nbr * objetPrix[idObjet][0][0];
                                MettreObjetDansSacNB(client, place, idObjet, nbr);
                                sauvegardeObjetEtCash(client);
                                sauvegardeObjetEtCash(clientVend);
                                PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                OuvirMenuSac(client);
                            } else {
                                if (compte == 2) {
                                    AjouterArgentCapitalAchats(clientVend, nbr * objetPrix[idObjet][0][0]);
                                    new var4 = clientBank[client];
                                    var4 = var4[0][0] - nbr * objetPrix[idObjet][0][0];
                                    MettreObjetDansSacNB(client, place, idObjet, nbr);
                                    sauvegardeObjetEtCash(client);
                                    sauvegardeObjetEtCash(clientVend);
                                    PrintToChat(clientVend, "%s Transaction valid‚ !", "[Rp Magnetik : ->]");
                                    OuvirMenuSac(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Le vendeur est trop loin !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le vendeur est partie !", "[Rp Magnetik : ->]");
        }
    } else {
        new var2;
        if (IsClientInGame(clientVend)) {
            decl String:steamID[32];
            GetClientAuthString(clientVend, steamID, 32);
            if (StrEqual(steamID, SteamVend, true)) {
                PrintToChat(clientVend, "%s Votre client a refuser !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

bool:posDeuxJoueur(client, clientTarget)
{
    decl Float:vec[3];
    decl Float:vecTarget[3];
    new var1;
    if (IsClientInGame(client)) {
        GetClientAbsOrigin(client, vec);
        GetClientAbsOrigin(clientTarget, vecTarget);
        if (RoundToNearest(GetVectorDistance(vec, vecTarget, false)) < 100) {
            return true;
        }
    }
    return false;
}

InitialeRaisonDeJail()
{
    strcopy(RaisonJail[4][0], 40, "Tentative de cambriolage");
    tempsDeJail[4] = 300;
    prixDeJail[4] = 500;
    strcopy(RaisonJail[8][0], 40, "Pickpocket sur un citoyen");
    tempsDeJail[8] = 300;
    prixDeJail[8] = 500;
    strcopy(RaisonJail[12][0], 40, "Crime commis sur civile");
    tempsDeJail[12] = 900;
    prixDeJail[12] = 1500;
    strcopy(RaisonJail[16][0], 40, "Crime commis sur flic");
    tempsDeJail[16] = 1200;
    prixDeJail[16] = 2000;
    strcopy(RaisonJail[20][0], 40, "Tentative de meurtre");
    tempsDeJail[20] = 300;
    prixDeJail[20] = 500;
    strcopy(RaisonJail[24][0], 40, "Racolage sur la voix public");
    tempsDeJail[24] = 300;
    prixDeJail[24] = 500;
    strcopy(RaisonJail[28][0], 40, "D‚tention d'arme ill‚gale");
    tempsDeJail[28] = 300;
    prixDeJail[28] = 500;
    strcopy(RaisonJail[32][0], 40, "Introduction dans une propri‚t‚ priv‚e");
    tempsDeJail[32] = 300;
    prixDeJail[32] = 500;
    strcopy(RaisonJail[36][0], 40, "Introduction dans le comico/fbi");
    tempsDeJail[36] = 420;
    prixDeJail[36] = 700;
    strcopy(RaisonJail[40][0], 40, "Nuissance sonore");
    tempsDeJail[40] = 300;
    prixDeJail[40] = 500;
    strcopy(RaisonJail[44][0], 40, "Aggression verbale");
    tempsDeJail[44] = 300;
    prixDeJail[44] = 500;
    strcopy(RaisonJail[48][0], 40, "Harc‚lement");
    tempsDeJail[48] = 300;
    prixDeJail[48] = 500;
    strcopy(RaisonJail[52][0], 40, "Tentative de fuite");
    tempsDeJail[52] = 600;
    prixDeJail[52] = 1000;
    strcopy(RaisonJail[56][0], 40, "Pour avoir Deco/reco");
    tempsDeJail[56] = 1200;
    prixDeJail[56] = 2000;
    return 0;
}

PlayerStartFlic(client)
{
    CancelClientMenu(client, false, Handle:0);
    new SonIdMetier = clientIdMetier[client][0][0];
    new var1;
    if (SonIdMetier == 2) {
        decl String:steamid[32];
        GetClientAuthString(client, steamid, 32);
        new Handle:g_MenuSecuritePrinc = CreateMenu(MenuHandler:51, MenuAction:28);
        SetMenuTitle(g_MenuSecuritePrinc, "| Menu de la s‚curit‚ |\n| Choisir une option |");
        decl String:buffer[4];
        Format(buffer, 4, "1");
        AddMenuItem(g_MenuSecuritePrinc, buffer, "T‚l‚porter en jail", 0);
        new var2;
        if (SonIdMetier == 2) {
            Format(buffer, 4, "2");
            AddMenuItem(g_MenuSecuritePrinc, buffer, "Tazer un citoyen", 0);
        }
        Format(buffer, 4, "3");
        AddMenuItem(g_MenuSecuritePrinc, buffer, "Information citoyen", 0);
        Format(buffer, 4, "4");
        AddMenuItem(g_MenuSecuritePrinc, buffer, "Liberation de jail", 0);
        if (SonIdMetier == 3) {
            if (clientTeam[client][0][0] == 2) {
                Format(buffer, 4, "5");
                AddMenuItem(g_MenuSecuritePrinc, buffer, "Faire Partie de la s‚curit‚", 0);
            }
            if (clientTeam[client][0][0] == 3) {
                Format(buffer, 4, "5");
                AddMenuItem(g_MenuSecuritePrinc, buffer, "Faire Partie des citoyens", 0);
            }
        }
        if (StrEqual(steamid, "STEAM_0:0:26796846", true)) {
            Format(buffer, 4, "6");
            AddMenuItem(g_MenuSecuritePrinc, buffer, "Donner de la vie !", 0);
        }
        Format(buffer, 4, "7");
        AddMenuItem(g_MenuSecuritePrinc, buffer, "Verrouiller / D‚verrouiller", 0);
        Format(buffer, 4, "8");
        AddMenuItem(g_MenuSecuritePrinc, buffer, "Supprimer une arme", 0);
        DisplayMenu(g_MenuSecuritePrinc, client, 0);
    } else {
        PrintToChat(client, "%s Vous ne faites pas partie de la s‚curit‚ !", "[Rp Magnetik : ->]");
    }
    return 0;
}

PlayerMettreEnJail(client)
{
    new SonIdMetier = clientIdMetier[client][0][0];
    new var1;
    if (SonIdMetier == 2) {
        if (visePlayerPolice(client)) {
            new clientTarget = GetClientAimTarget(client, true);
            decl String:SteamTarget[32];
            GetClientAuthString(clientTarget, SteamTarget, 32);
            decl String:nameTarget[32];
            GetClientName(clientTarget, nameTarget, 32);
            CancelClientMenu(clientTarget, false, Handle:0);
            teleporterJoueurEnJail(clientTarget);
            clientInJail[clientTarget] = 1;
            clientTimeInJail[clientTarget] = 30;
            new Handle:g_MenuRaisonDeJail = CreateMenu(MenuHandler:77, MenuAction:28);
            decl String:titre[60];
            Format(titre, 60, "| Raison d'emprisonnement |\n De %s", nameTarget);
            SetMenuTitle(g_MenuRaisonDeJail, titre);
            decl String:buff[64];
            decl String:param[64];
            new i = 1;
            while (i < 15) {
                Format(buff, 64, "%d,%d,%s", i, clientTarget, SteamTarget);
                Format(param, 64, "%s", RaisonJail[i][0][0]);
                AddMenuItem(g_MenuRaisonDeJail, buff, param, 0);
                i++;
            }
            DisplayMenu(g_MenuRaisonDeJail, client, 300);
        }
        PlayerStartFlic(client);
    }
    return 0;
}

public BlockMenuDeLaSecurite(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new valeur = StringToInt(parametre, 10);
    if (valeur == 1) {
        if (visePlayerPolice(client)) {
            new clientTarget = GetClientAimTarget(client, true);
            decl String:SteamTarget[32];
            GetClientAuthString(clientTarget, SteamTarget, 32);
            decl String:nameTarget[32];
            GetClientName(clientTarget, nameTarget, 32);
            CancelClientMenu(clientTarget, false, Handle:0);
            teleporterJoueurEnJail(clientTarget);
            clientInJail[clientTarget] = 1;
            clientTimeInJail[clientTarget] = 30;
            new Handle:g_MenuRaisonDeJail = CreateMenu(MenuHandler:77, MenuAction:28);
            decl String:titre[60];
            Format(titre, 60, "| Raison d'emprisonnement |\n De %s", nameTarget);
            SetMenuTitle(g_MenuRaisonDeJail, titre);
            decl String:buff[64];
            decl String:param[64];
            new i = 1;
            while (i < 15) {
                Format(buff, 64, "%d,%d,%s", i, clientTarget, SteamTarget);
                Format(param, 64, "%s", RaisonJail[i][0][0]);
                AddMenuItem(g_MenuRaisonDeJail, buff, param, 0);
                i++;
            }
            DisplayMenu(g_MenuRaisonDeJail, client, 300);
        } else {
            PlayerStartFlic(client);
        }
    } else {
        if (valeur == 2) {
            if (visePlayerPolice(client)) {
                new clientTarget = GetClientAimTarget(client, true);
                new sonIdMetier = clientIdMetier[clientTarget][0][0];
                new var1;
                if (sonIdMetier != 2) {
                    if (!buttondelay[client][0][0]) {
                        buttondelay[client] = 1;
                        CreateTimer(0.5, ResetDelay, client, 0);
                        tazerUnJoueur(client, clientTarget);
                    }
                    PlayerStartFlic(client);
                } else {
                    PrintToChat(client, "%s Vous ne pouvez pas tazer un agent de securit‚ !", "[Rp Magnetik : ->]");
                }
            } else {
                PlayerStartFlic(client);
            }
        }
        if (valeur == 3) {
            InfoJoueurVise(client);
        }
        if (valeur == 4) {
            new Handle:menuLiberation = CreateMenu(MenuHandler:275, MenuAction:28);
            SetMenuTitle(menuLiberation, "Choisir un joueur :");
            decl String:clientName[32];
            decl String:SteamID[32];
            decl String:Buffer[128];
            new i = 1;
            while (i <= MaxClients) {
                new var2;
                if (IsClientInGame(i)) {
                    if (clientInJail[i][0][0]) {
                        GetClientAuthString(i, SteamID, 32);
                        Format(Buffer, 128, "%d,%s", i, SteamID);
                        GetClientName(i, clientName, 32);
                        AddMenuItem(menuLiberation, Buffer, clientName, 0);
                    }
                }
                i++;
            }
            Format(Buffer, 128, "0,aucun");
            AddMenuItem(menuLiberation, Buffer, "-> Retour", 0);
            DisplayMenu(menuLiberation, client, 300);
        }
        if (valeur == 5) {
            if (clientTeam[client][0][0] == 2) {
                ChangerEquipe(client, 3);
                strcopy(clientSkin[client][0][0], 32, "wesker");
                DonnerUnSkinJoueur(client);
                if (!JoeurInscripEventG(client)) {
                    SetEntityHealth(client, 500);
                }
                PlayerStartFlic(client);
            } else {
                if (clientTeam[client][0][0] == 3) {
                    ChangerEquipe(client, 2);
                    strcopy(clientSkin[client][0][0], 32, "t_leet");
                    DonnerUnSkinJoueur(client);
                    if (!JoeurInscripEventG(client)) {
                        SetEntityHealth(client, 100);
                    }
                    PlayerStartFlic(client);
                }
            }
        }
        if (valeur == 6) {
            SetEntityHealth(client, 500);
            GivePlayerItem(client, "item_assaultsuit", 0);
            PlayerStartFlic(client);
        }
        if (valeur == 8) {
            new entity = GetClientAimTarget(client, false);
            if (entity != -1) {
                decl String:ClassName[32];
                GetEdictClassname(entity, ClassName, 32);
                new var3;
                if (armeList(ClassName, armePrimaire, 6)) {
                    RemoveEdict(entity);
                    PrintToChat(client, "%s Arme supprimer", "[Rp Magnetik : ->]");
                } else {
                    if (StrEqual(ClassName, "prop_physics", true)) {
                        new var4;
                        if (clientIdMetier[client][0][0] == 2) {
                            RemoveEdict(entity);
                            PrintToChat(client, "%s Objets supprimer", "[Rp Magnetik : ->]");
                        }
                    }
                }
            }
            PlayerStartFlic(client);
        }
        if (valeur == 7) {
            LockUnePorte(client);
            PlayerStartFlic(client);
        }
    }
    return 0;
}

public blockLiberationDeJail(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[128];
    decl String:split[8][32];
    GetMenuItem(menu, choice, parametre, 128, 0, "", 0);
    ExplodeString(parametre, ",", split, 2, 32);
    new clientTarget = StringToInt(split[0][split], 10);
    if (clientTarget) {
        new var1;
        if (IsClientInGame(clientTarget)) {
            decl String:steamTarget[32];
            GetClientAuthString(clientTarget, steamTarget, 32);
            if (StrEqual(steamTarget, split[4], true)) {
                if (clientInJail[clientTarget][0][0]) {
                    FinDeJailJoueur(clientTarget);
                    CancelClientMenu(clientTarget, false, Handle:0);
                    decl String:clientName[32];
                    GetClientName(client, clientName, 32);
                    decl String:clientNameT[32];
                    GetClientName(clientTarget, clientNameT, 32);
                    new iclient = 1;
                    while (iclient <= MaxClients) {
                        new var2;
                        if (IsClientInGame(iclient)) {
                            new var3;
                            if (clientIdMetier[iclient][0][0] == 2) {
                                PrintToChat(iclient, "%s %s viens d'ˆtre lib‚r‚ par un agent s‚curit‚ : %s", "[Rp Magnetik : ->]", clientNameT, clientName);
                                iclient++;
                            }
                            iclient++;
                        }
                        iclient++;
                    }
                    PrintToChat(client, "%s Citoyen lib‚r‚ !", "[Rp Magnetik : ->]");
                    PlayerStartFlic(client);
                }
            }
        }
    } else {
        PlayerStartFlic(client);
    }
    return 0;
}

public BlockMenuRaisonDeJail(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[64];
    decl String:split[20][32];
    GetMenuItem(menu, choice, parametre, 64, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 32);
    new valeur = StringToInt(split[0][split], 10);
    new clientTarget = StringToInt(split[4], 10);
    new var1;
    if (IsClientInGame(clientTarget)) {
        decl String:steamTarget[32];
        GetClientAuthString(clientTarget, steamTarget, 32);
        if (StrEqual(steamTarget, split[8], true)) {
            if (clientInJail[clientTarget][0][0]) {
                clientTimeInJail[clientTarget] = tempsDeJail[valeur][0][0];
                decl String:steamidPolice[32];
                GetClientAuthString(client, steamidPolice, 32);
                new Handle:g_MenuSortirDeJail = CreateMenu(MenuHandler:49, MenuAction:28);
                decl String:titre[64];
                Format(titre, 64, "| Caution de prison |\nPayer %d $ pour sortir", prixDeJail[valeur]);
                SetMenuTitle(g_MenuSortirDeJail, titre);
                decl String:buffer[64];
                Format(buffer, 64, "1,%d,%d,%s", prixDeJail[valeur], client, steamidPolice);
                AddMenuItem(g_MenuSortirDeJail, buffer, "-> Accepter", 0);
                Format(buffer, 64, "2,%d,%d,%s", prixDeJail[valeur], client, steamidPolice);
                AddMenuItem(g_MenuSortirDeJail, buffer, "-> Refuser", 0);
                DisplayMenu(g_MenuSortirDeJail, clientTarget, 300);
                decl String:clientName[32];
                GetClientName(client, clientName, 32);
                PrintToChat(clientTarget, "%s Vous avez ‚t‚ emprisonn‚ par %s raison : %s dur‚e %d secondes !", "[Rp Magnetik : ->]", clientName, RaisonJail[valeur][0][0], tempsDeJail[valeur]);
            } else {
                PrintToChat(client, "%s il d‚ja sortie de prison car vous n'avez pas ‚tes ass‚ rapide !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Le Citoyen est partie !", "[Rp Magnetik : ->]");
        }
    }
    PlayerStartFlic(client);
    return 0;
}

public BlockMenuConfirSortirJail(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[64];
    decl String:split[16][32];
    GetMenuItem(menu, choice, parametre, 64, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 32);
    new valeur = StringToInt(split[0][split], 10);
    new argent = StringToInt(split[4], 10);
    new clientPolice = StringToInt(split[8], 10);
    if (valeur == 1) {
        if (clientInJail[client][0][0]) {
            new cash = clientCash[client][0][0];
            new bank = clientBank[client][0][0];
            if (cash >= argent) {
                new var3 = clientCash[client];
                var3 = var3[0][0] - argent;
                clientTimeInJail[client] = clientTimeInJail[client][0][0] / 2;
                PrintToChat(client, "%s Votre peine de prison a ‚t‚ diminu‚ !", "[Rp Magnetik : ->]");
                new var1;
                if (IsClientInGame(clientPolice)) {
                    decl String:steamTarget[32];
                    GetClientAuthString(clientPolice, steamTarget, 32);
                    if (StrEqual(steamTarget, split[12], true)) {
                        if (clientRibe[clientPolice][0][0]) {
                            new var4 = clientBank[clientPolice];
                            var4 = argent * 20 / 100 + var4[0][0];
                        } else {
                            new var5 = clientCash[clientPolice];
                            var5 = argent * 20 / 100 + var5[0][0];
                        }
                        DonnerArgentALaTG(argent * 80 / 100);
                        PrintToChat(clientPolice, "%s Le prisonnier … payer sa caution donc vous gagnez : %d $ !", "[Rp Magnetik : ->]", argent * 20 / 100);
                    }
                }
            } else {
                if (bank >= argent) {
                    new var6 = clientBank[client];
                    var6 = var6[0][0] - argent;
                    clientTimeInJail[client] = clientTimeInJail[client][0][0] / 2;
                    PrintToChat(client, "%s Votre peine de prison a ‚t‚ diminu‚ !", "[Rp Magnetik : ->]");
                    new var2;
                    if (IsClientInGame(clientPolice)) {
                        decl String:steamTarget[32];
                        GetClientAuthString(clientPolice, steamTarget, 32);
                        if (StrEqual(steamTarget, split[12], true)) {
                            if (clientRibe[clientPolice][0][0]) {
                                new var7 = clientBank[clientPolice];
                                var7 = argent * 20 / 100 + var7[0][0];
                            } else {
                                new var8 = clientCash[clientPolice];
                                var8 = argent * 20 / 100 + var8[0][0];
                            }
                            DonnerArgentALaTG(argent * 80 / 100);
                            PrintToChat(clientPolice, "%s Le prisonnier … payer sa caution donc vous gagnez : %d $ !", "[Rp Magnetik : ->]", argent * 20 / 100);
                        }
                    }
                }
                PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

FinDeJailJoueur(client)
{
    new var1;
    if (IsClientInGame(client)) {
        clientInJail[client] = 0;
        clientTimeInJail[client] = 0;
        TeleportEntity(client, SpawnFinJail, NULL_VECTOR, NULL_VECTOR);
        SlapPlayer(client, 0, false);
        SlapPlayer(client, 0, false);
        PrintToChat(client, "%s Votre p‚riode de jail est termin‚ !", "[Rp Magnetik : ->]");
    }
    return 0;
}

teleporterJoueurEnJail(client)
{
    new var1;
    if (IsClientInGame(client)) {
        new valeur = GetRandomInt(1, 4);
        decl Float:origin[3];
        if (valeur == 1) {
            origin[0] = Jail1[0][0];
            origin[4] = Jail1[4][0];
            origin[8] = Jail1[8][0];
        } else {
            if (valeur == 2) {
                origin[0] = Jail2[0][0];
                origin[4] = Jail2[4][0];
                origin[8] = Jail2[8][0];
            }
            if (valeur == 3) {
                origin[0] = Jail3[0][0];
                origin[4] = Jail3[4][0];
                origin[8] = Jail3[8][0];
            }
            if (valeur == 4) {
                origin[0] = Jail4[0][0];
                origin[4] = Jail4[4][0];
                origin[8] = Jail4[8][0];
            }
        }
        TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
        new g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
        if (g_offsCollisionGroup != -1) {
            SetEntData(client, g_offsCollisionGroup, any:2, 4, true);
            CreateTimer(2, ModeNoBlockParDefault, client, 0);
        }
        new g_Entity = CreateEntityByName("player_weaponstrip", -1);
        AcceptEntityInput(g_Entity, "StripWeaponsAndSuit", client, -1, 0);
        AcceptEntityInput(g_Entity, "Kill", -1, -1, 0);
        new var2;
        if (GetClientTeam(client) > 1) {
            CreateTimer(0.5, donnerUnKnife, client, 0);
        }
    }
    return 0;
}

public Action:ModeNoBlockParDefault(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        new g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
        if (g_offsCollisionGroup != -1) {
            SetEntData(client, g_offsCollisionGroup, any:0, 4, true);
        }
    }
    return Action:0;
}

ChangerEquipe(client, valeur)
{
    new var1;
    if (valeur > 0) {
        clientTeam[client] = valeur;
        CS_SwitchTeam(client, valeur);
        if (valeur == 2) {
            PrintToChat(client, "%s Vous faites partie des citoyens !", "[Rp Magnetik : ->]");
        }
        if (valeur == 3) {
            PrintToChat(client, "%s Vous faites partie de la s‚curit‚ !", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

InfoJoueurVise(client)
{
    new LeClientTarget = GetClientAimTarget(client, true);
    if (LeClientTarget != -1) {
        new SonIdMetier = clientIdMetier[client][0][0];
        new var1;
        if (SonIdMetier == 3) {
            decl String:nameTarget[32];
            GetClientName(LeClientTarget, nameTarget, 32);
            new Handle:g_MenuInfoJoueur = CreateMenu(MenuHandler:61, MenuAction:28);
            decl String:titre[256];
            Format(titre, 256, "| Information Joueur |\nNom : %s\nPort d'arme secondaire : %d\nPort d'arme primaire : %d\nPrisonnier : %d\n(0 = Non / 1 = Oui)", nameTarget, clientPermiSec[LeClientTarget], clientPermiPri[LeClientTarget], clientInJail[LeClientTarget]);
            SetMenuTitle(g_MenuInfoJoueur, titre);
            decl String:buffer[4];
            Format(buffer, 4, "1");
            AddMenuItem(g_MenuInfoJoueur, buffer, "-> Retour", 0);
            DisplayMenu(g_MenuInfoJoueur, client, 300);
        } else {
            if (SonIdMetier == 2) {
                decl String:nameTarget[32];
                GetClientName(LeClientTarget, nameTarget, 32);
                new Handle:g_MenuInfoJoueurPrChef = CreateMenu(MenuHandler:65, MenuAction:28);
                decl String:titre[256];
                Format(titre, 256, "| Information Joueur |\nNom : %s\nPermi d'A sec : %d Permi d'A pri : %d\n Cash : %d\n Bank : %d\nMetier : %s\nPrisonnier : %d\nLevel Knife : %d/100", nameTarget, clientPermiSec[LeClientTarget], clientPermiPri[LeClientTarget], clientCash[LeClientTarget], clientBank[LeClientTarget], metierNom[clientIdMetier[LeClientTarget][0][0]][0][0], clientInJail[LeClientTarget], clientLevelKnife[LeClientTarget]);
                SetMenuTitle(g_MenuInfoJoueurPrChef, titre);
                decl String:buffer[4];
                Format(buffer, 4, "1");
                AddMenuItem(g_MenuInfoJoueurPrChef, buffer, "-> Retour", 0);
                DisplayMenu(g_MenuInfoJoueurPrChef, client, 300);
            }
        }
    } else {
        PrintToChat(client, "%s Vous n'avez pas vis‚ quelqu'un !", "[Rp Magnetik : ->]");
        PlayerStartFlic(client);
    }
    return 0;
}

public BlockMenuInfoPourChef(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new valeur = StringToInt(parametre, 10);
    if (valeur == 1) {
        PlayerStartFlic(client);
    }
    return 0;
}

public BlockMenuInfoJoueur(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new valeur = StringToInt(parametre, 10);
    if (valeur == 1) {
        PlayerStartFlic(client);
    }
    return 0;
}

bool:visePlayerPolice(client)
{
    if (GetClientAimTarget(client, true) != -1) {
        decl Float:vec[3];
        decl Float:vecTarget[3];
        GetClientAbsOrigin(client, vec);
        GetClientAbsOrigin(GetClientAimTarget(client, true), vecTarget);
        if (RoundToNearest(GetVectorDistance(vec, vecTarget, false)) < 1000) {
            return true;
        }
    }
    return false;
}

Powersbeacon()
{
    g_BeaconSprite = PrecacheModel("materials/sprites/lgtning.vmt", false);
    g_Lightning = PrecacheModel("sprites/lgtning.vmt", false);
    return 0;
}


/* ERROR! unknown operator */
 function "CrochetageDePorte" (number 219)
public Action:ColorPLayerDefaut(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        SetEntityRenderColor(client, 255, 255, 255, 255);
    }
    return Action:0;
}

public Action:SucceDeDeverrouillage(Handle:timer, Handle:pack)
{
    decl String:parametre[16];
    decl String:split[8][8];
    new client = 0;
    ResetPack(pack, false);
    client = ReadPackCell(pack);
    ReadPackString(pack, parametre, 16);
    ExplodeString(parametre, ",", split, 2, 8);
    new cli = StringToInt(split[0][split], 10);
    new entity = StringToInt(split[4], 10);
    new var1;
    if (IsClientInGame(cli)) {
        if (ProcheJoueurPorte(entity, cli)) {
            AcceptEntityInput(entity, "unlock", -1, -1, 0);
            PrintToChat(cli, "%s porte d‚verrouill‚e !", "[Rp Magnetik : ->]");
        }
        PrintToChat(cli, "%s ‚chec de d‚verrouillage (Trop loin de la porte) !", "[Rp Magnetik : ->]");
    }
    return Action:0;
}

public Action:EchecDeDeverrouillage(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        PrintToChat(client, "%s ‚chec de d‚verrouillage !", "[Rp Magnetik : ->]");
    }
    return Action:0;
}

bool:memeFafia(IdMetier, IdMetierTarget)
{
    new var1;
    if (IdMetier == 35) {
        return true;
    }
    new var4;
    if (IdMetier == 37) {
        return true;
    }
    new var7;
    if (IdMetier == 39) {
        return true;
    }
    return false;
}


/* ERROR! unknown operator */
 function "PickUPArgentJoueur" (number 224)
public Action:VoleUnJoueur(Handle:timer, Handle:pack)
{
    decl String:parametre[64];
    decl String:split[8][32];
    new client = 0;
    ResetPack(pack, false);
    client = ReadPackCell(pack);
    ReadPackString(pack, parametre, 64);
    ExplodeString(parametre, ",", split, 2, 32);
    new clientTarget = StringToInt(split[4], 10);
    new var1;
    if (IsClientInGame(client)) {
        decl String:steamTarget[32];
        GetClientAuthString(clientTarget, steamTarget, 32);
        if (StrEqual(steamTarget, split[0][split], true)) {
            if (presDujoueur(client, clientTarget)) {
                if (clientTempsPasse[clientTarget][0][0] > 10) {
                    new argent = clientCash[clientTarget][0][0];
                    if (0 < argent) {
                        if (argent > 100) {
                            new valeur = GetRandomInt(50, 100);
                            AjouterArgentCapitalAchats(client, valeur);
                            new var2 = clientCash[clientTarget];
                            var2 = var2[0][0] - valeur;
                            PrintToChat(clientTarget, "%s Quelqu'un vous a voler %d $ !", "[Rp Magnetik : ->]", valeur);
                            PrintToChat(client, "%s Vous venez de voler %d $ !", "[Rp Magnetik : ->]", valeur);
                            clientFermeture[client] = 40;
                        } else {
                            new valeur = GetRandomInt(1, argent);
                            AjouterArgentCapitalAchats(client, valeur);
                            new var3 = clientCash[clientTarget];
                            var3 = var3[0][0] - valeur;
                            PrintToChat(clientTarget, "%s Quelqu'un vous a voler %d $ !", "[Rp Magnetik : ->]", valeur);
                            PrintToChat(client, "%s Vous venez de voler %d $ !", "[Rp Magnetik : ->]", valeur);
                            clientFermeture[client] = 40;
                        }
                    } else {
                        clientFermeture[client] = 40;
                        PrintToChat(client, "%s Il n'y as plus d'argent dans ses poches !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s C'est un nouveau citoyen donc tu ne peux pas le voler pour l'instant !", "[Rp Magnetik : ->]");
                    PrintToChat(clientTarget, "%s Quelqu'un a essay‚ de vous voler, soyez prudent !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous trop loin de la personne !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s La personne que vous voulez voler est partie !", "[Rp Magnetik : ->]");
        }
    }
    return Action:0;
}

bool:presDujoueur(client, clientTarget)
{
    new var1;
    if (client) {
        decl Float:vec[3];
        decl Float:vecTarget[3];
        GetClientAbsOrigin(client, vec);
        GetClientAbsOrigin(clientTarget, vecTarget);
        if (RoundToNearest(GetVectorDistance(vec, vecTarget, false)) < 60) {
            return true;
        }
    }
    return false;
}

affichageMenuBank(client, entity)
{
    if (ProcheJoueurPorte(entity, client)) {
        new Handle:g_MenuBanque = CreateMenu(MenuHandler:47, MenuAction:28);
        SetMenuTitle(g_MenuBanque, "| Mon Compte Banquaire |");
        decl String:parametre[16];
        Format(parametre, 16, "1,%d", entity);
        AddMenuItem(g_MenuBanque, parametre, "D‚poser de l'argent", 0);
        Format(parametre, 16, "2,%d", entity);
        AddMenuItem(g_MenuBanque, parametre, "Retirer de l'argent", 0);
        if (clientDepoBank[client][0][0]) {
            Format(parametre, 16, "3,%d", entity);
            AddMenuItem(g_MenuBanque, parametre, "D‚poser des objets", 0);
            Format(parametre, 16, "4,%d", entity);
            AddMenuItem(g_MenuBanque, parametre, "Retirer des objets", 0);
        }
        if (!clientFermeture[client][0][0]) {
            Format(parametre, 16, "5,%d", entity);
            AddMenuItem(g_MenuBanque, parametre, "Sauvegarder mes donn‚s", 0);
        }
        DisplayMenu(g_MenuBanque, client, 300);
    }
    return 0;
}

public BlockMenuBanque(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[12][16];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 16);
    new num = StringToInt(split[0][split], 10);
    new entity = StringToInt(split[4], 10);
    if (num == 1) {
        if (ProcheJoueurPorte(entity, client)) {
            new Handle:g_MenudepoBanque = CreateMenu(MenuHandler:157, MenuAction:28);
            SetMenuTitle(g_MenudepoBanque, "| Deposer de l'argent |");
            decl String:para[16];
            Format(para, 16, "1,%d", entity);
            AddMenuItem(g_MenudepoBanque, para, "100$", 0);
            Format(para, 16, "2,%d", entity);
            AddMenuItem(g_MenudepoBanque, para, "200$", 0);
            Format(para, 16, "3,%d", entity);
            AddMenuItem(g_MenudepoBanque, para, "500$", 0);
            Format(para, 16, "4,%d", entity);
            AddMenuItem(g_MenudepoBanque, para, "1000$", 0);
            Format(para, 16, "5,%d", entity);
            AddMenuItem(g_MenudepoBanque, para, "2000$", 0);
            Format(para, 16, "6,%d", entity);
            AddMenuItem(g_MenudepoBanque, para, "5000$", 0);
            Format(para, 16, "7,%d", entity);
            AddMenuItem(g_MenudepoBanque, para, "La totalit‚", 0);
            DisplayMenu(g_MenudepoBanque, client, 300);
        } else {
            PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
        }
    } else {
        if (num == 2) {
            if (ProcheJoueurPorte(entity, client)) {
                new Handle:g_MenuRetirBanque = CreateMenu(MenuHandler:175, MenuAction:28);
                SetMenuTitle(g_MenuRetirBanque, "| Retirer de l'argent |");
                decl String:param[16];
                Format(param, 16, "1,%d", entity);
                AddMenuItem(g_MenuRetirBanque, param, "100$", 0);
                Format(param, 16, "2,%d", entity);
                AddMenuItem(g_MenuRetirBanque, param, "200$", 0);
                Format(param, 16, "3,%d", entity);
                AddMenuItem(g_MenuRetirBanque, param, "500$", 0);
                Format(param, 16, "4,%d", entity);
                AddMenuItem(g_MenuRetirBanque, param, "1000$", 0);
                Format(param, 16, "5,%d", entity);
                AddMenuItem(g_MenuRetirBanque, param, "2000$", 0);
                Format(param, 16, "6,%d", entity);
                AddMenuItem(g_MenuRetirBanque, param, "5000$", 0);
                Format(param, 16, "7,%d", entity);
                AddMenuItem(g_MenuRetirBanque, param, "La totalit‚", 0);
                DisplayMenu(g_MenuRetirBanque, client, 300);
            } else {
                PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
            }
        }
        if (num == 3) {
            afficherObjetDuSac(client, entity);
        }
        if (num == 4) {
            retirerObjetsDeBac(client, entity);
        }
        if (num == 5) {
            sauvegarderInfosClient(client);
            clientFermeture[client] = 40;
            PrintToChat(client, "%s Vos donn‚es sont sauvegard‚es", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

retirerObjetsDeBac(client, entity)
{
    if (ProcheJoueurPorte(entity, client)) {
        decl String:split[84][8];
        ExplodeString(clientObjetBank[client][0][0], ",", split, 21, 5);
        decl tab[10];
        tab[0] = StringToInt(split[4], 10);
        tab[4] = StringToInt(split[12], 10);
        tab[8] = StringToInt(split[20], 10);
        tab[12] = StringToInt(split[28], 10);
        tab[16] = StringToInt(split[36], 10);
        tab[20] = StringToInt(split[44], 10);
        tab[24] = StringToInt(split[52], 10);
        tab[28] = StringToInt(split[60], 10);
        tab[32] = StringToInt(split[68], 10);
        tab[36] = StringToInt(split[76], 10);
        decl tabNbr[10];
        tabNbr[0] = StringToInt(split[0][split], 10);
        tabNbr[4] = StringToInt(split[8], 10);
        tabNbr[8] = StringToInt(split[16], 10);
        tabNbr[12] = StringToInt(split[24], 10);
        tabNbr[16] = StringToInt(split[32], 10);
        tabNbr[20] = StringToInt(split[40], 10);
        tabNbr[24] = StringToInt(split[48], 10);
        tabNbr[28] = StringToInt(split[56], 10);
        tabNbr[32] = StringToInt(split[64], 10);
        tabNbr[36] = StringToInt(split[72], 10);
        if (tabNbr[0]) {
            new Handle:g_MenuScBank = CreateMenu(MenuHandler:99, MenuAction:28);
            SetMenuTitle(g_MenuScBank, "| Quel objets voulez-vous |\n| mettre en sac ? |");
            decl String:buffer[16];
            decl String:InfoObjet[60];
            new i = 0;
            while (i < 10) {
                if (tabNbr[i]) {
                    Format(buffer, 16, "%d,%d,%d", i, tab[i], entity);
                    Format(InfoObjet, 60, "%d %s %d:%s", tabNbr[i], objetNom[tab[i]][0][0], objetEffet[tab[i]], objetFonction[tab[i]][0][0]);
                    AddMenuItem(g_MenuScBank, buffer, InfoObjet, 0);
                    i++;
                }
                i++;
            }
            DisplayMenu(g_MenuScBank, client, 300);
        } else {
            PrintToChat(client, "%s Vous n'avez pas objets !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockRetirObjetDeBank(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[16][12];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 10);
    new idsac = StringToInt(split[0][split], 10) + 1;
    new idObjet = StringToInt(split[4], 10);
    new entity = StringToInt(split[8], 10);
    if (ProcheJoueurPorte(entity, client)) {
        if (idObjet) {
            if (idObjet != 64) {
                decl String:titre[60];
                new Handle:g_MenuPoseDobjet = CreateMenu(MenuHandler:97, MenuAction:28);
                Format(titre, 60, "| Combien de : %s |\nVoulez-vous retirer ?", objetNom[idObjet][0][0]);
                SetMenuTitle(g_MenuPoseDobjet, titre);
                decl String:para[40];
                decl String:buffer[60];
                Format(para, 40, "1,%d,%d,%d", idObjet, idsac, entity);
                Format(buffer, 60, "Nbr 1 : %s", objetNom[idObjet][0][0]);
                AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
                Format(para, 40, "2,%d,%d,%d", idObjet, idsac, entity);
                Format(buffer, 60, "Nbr 2 : %s", objetNom[idObjet][0][0]);
                AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
                Format(para, 40, "5,%d,%d,%d", idObjet, idsac, entity);
                Format(buffer, 60, "Nbr 5 : %s", objetNom[idObjet][0][0]);
                AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
                Format(para, 40, "10,%d,%d,%d", idObjet, idsac, entity);
                Format(buffer, 60, "Nbr 10 : %s", objetNom[idObjet][0][0]);
                AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
                Format(para, 40, "20,%d,%d,%d", idObjet, idsac, entity);
                Format(buffer, 60, "Nbr 20 : %s", objetNom[idObjet][0][0]);
                AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
                Format(para, 40, "50,%d,%d,%d", idObjet, idsac, entity);
                Format(buffer, 60, "Nbr 50 : %s", objetNom[idObjet][0][0]);
                AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
                DisplayMenu(g_MenuPoseDobjet, client, 300);
            } else {
                new place = TrouverPlaceDansSac(client, 64);
                if (place) {
                    new nbrKit = TrouverLeNombredeKit(client);
                    if (nbrKit < 15) {
                        remettreOrdreBankPrSac(client, idsac, 1);
                        MettreObjetDansSac(client, place, 64);
                        PrintToChat(client, "%s Kit de crochetage rajout‚ dans votre sac !", "[Rp Magnetik : ->]");
                        retirerObjetsDeBac(client, entity);
                    } else {
                        PrintToChat(client, "%s Vous avez d‚j… %d kit de crochetage dans votre sac !", "[Rp Magnetik : ->]", 15);
                    }
                } else {
                    PrintToChat(client, "%s Vous avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
                }
            }
        } else {
            PrintToChat(client, "%s Objets incorrecte ! ", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockRetirAutantDobjet(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[40];
    decl String:split[20][8];
    GetMenuItem(menu, choice, parametre, 40, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 8);
    new nombre = StringToInt(split[0][split], 10);
    new idObjet = StringToInt(split[4], 10);
    new idsac = StringToInt(split[8], 10);
    new entity = StringToInt(split[12], 10);
    if (ProcheJoueurPorte(entity, client)) {
        if (aLesObjetsEnBank(client, idObjet, nombre)) {
            new place = TrouverPlaceDansSacNB(client, idObjet, nombre);
            if (place) {
                remettreOrdreBankPrSac(client, idsac, nombre);
                MettreObjetDansSacNB(client, place, idObjet, nombre);
                PrintToChat(client, "%s %d %s ont etaient ajout‚s dans le sac !", "[Rp Magnetik : ->]", nombre, objetNom[idObjet][0][0]);
                retirerObjetsDeBac(client, entity);
            } else {
                PrintToChat(client, "%s Vous n'avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas %d %s en banque !", "[Rp Magnetik : ->]", nombre, objetNom[idObjet][0][0]);
        }
    } else {
        PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
    }
    return 0;
}

remettreOrdreBankPrSac(client, idsac, nombre)
{
    decl String:split[84][8];
    ExplodeString(clientObjetBank[client][0][0], ",", split, 21, 5);
    decl tab[10];
    tab[0] = StringToInt(split[4], 10);
    tab[4] = StringToInt(split[12], 10);
    tab[8] = StringToInt(split[20], 10);
    tab[12] = StringToInt(split[28], 10);
    tab[16] = StringToInt(split[36], 10);
    tab[20] = StringToInt(split[44], 10);
    tab[24] = StringToInt(split[52], 10);
    tab[28] = StringToInt(split[60], 10);
    tab[32] = StringToInt(split[68], 10);
    tab[36] = StringToInt(split[76], 10);
    decl tabNbr[10];
    tabNbr[0] = StringToInt(split[0][split], 10);
    tabNbr[4] = StringToInt(split[8], 10);
    tabNbr[8] = StringToInt(split[16], 10);
    tabNbr[12] = StringToInt(split[24], 10);
    tabNbr[16] = StringToInt(split[32], 10);
    tabNbr[20] = StringToInt(split[40], 10);
    tabNbr[24] = StringToInt(split[48], 10);
    tabNbr[28] = StringToInt(split[56], 10);
    tabNbr[32] = StringToInt(split[64], 10);
    tabNbr[36] = StringToInt(split[72], 10);
    if (idsac == 1) {
        if (tabNbr[0] - nombre < 1) {
            tabNbr[0] = tabNbr[4];
            tab[0] = tab[4];
            tabNbr[4] = tabNbr[8];
            tab[4] = tab[8];
            tabNbr[8] = tabNbr[12];
            tab[8] = tab[12];
            tabNbr[12] = tabNbr[16];
            tab[12] = tab[16];
            tabNbr[16] = tabNbr[20];
            tab[16] = tab[20];
            tabNbr[20] = tabNbr[24];
            tab[20] = tab[24];
            tabNbr[24] = tabNbr[28];
            tab[24] = tab[28];
            tabNbr[28] = tabNbr[32];
            tab[28] = tab[32];
            tabNbr[32] = tabNbr[36];
            tab[32] = tab[36];
            tabNbr[36] = 0;
            tab[36] = 0;
        } else {
            tabNbr[0] = tabNbr[0] - nombre;
        }
    } else {
        if (idsac == 2) {
            if (tabNbr[4] - nombre < 1) {
                tabNbr[4] = tabNbr[8];
                tab[4] = tab[8];
                tabNbr[8] = tabNbr[12];
                tab[8] = tab[12];
                tabNbr[12] = tabNbr[16];
                tab[12] = tab[16];
                tabNbr[16] = tabNbr[20];
                tab[16] = tab[20];
                tabNbr[20] = tabNbr[24];
                tab[20] = tab[24];
                tabNbr[24] = tabNbr[28];
                tab[24] = tab[28];
                tabNbr[28] = tabNbr[32];
                tab[28] = tab[32];
                tabNbr[32] = tabNbr[36];
                tab[32] = tab[36];
                tabNbr[36] = 0;
                tab[36] = 0;
            } else {
                tabNbr[4] -= nombre;
            }
        }
        if (idsac == 3) {
            if (tabNbr[8] - nombre < 1) {
                tabNbr[8] = tabNbr[12];
                tab[8] = tab[12];
                tabNbr[12] = tabNbr[16];
                tab[12] = tab[16];
                tabNbr[16] = tabNbr[20];
                tab[16] = tab[20];
                tabNbr[20] = tabNbr[24];
                tab[20] = tab[24];
                tabNbr[24] = tabNbr[28];
                tab[24] = tab[28];
                tabNbr[28] = tabNbr[32];
                tab[28] = tab[32];
                tabNbr[32] = tabNbr[36];
                tab[32] = tab[36];
                tabNbr[36] = 0;
                tab[36] = 0;
            } else {
                tabNbr[8] -= nombre;
            }
        }
        if (idsac == 4) {
            if (tabNbr[12] - nombre < 1) {
                tabNbr[12] = tabNbr[16];
                tab[12] = tab[16];
                tabNbr[16] = tabNbr[20];
                tab[16] = tab[20];
                tabNbr[20] = tabNbr[24];
                tab[20] = tab[24];
                tabNbr[24] = tabNbr[28];
                tab[24] = tab[28];
                tabNbr[28] = tabNbr[32];
                tab[28] = tab[32];
                tabNbr[32] = tabNbr[36];
                tab[32] = tab[36];
                tabNbr[36] = 0;
                tab[36] = 0;
            } else {
                tabNbr[12] -= nombre;
            }
        }
        if (idsac == 5) {
            if (tabNbr[16] - nombre < 1) {
                tabNbr[16] = tabNbr[20];
                tab[16] = tab[20];
                tabNbr[20] = tabNbr[24];
                tab[20] = tab[24];
                tabNbr[24] = tabNbr[28];
                tab[24] = tab[28];
                tabNbr[28] = tabNbr[32];
                tab[28] = tab[32];
                tabNbr[32] = tabNbr[36];
                tab[32] = tab[36];
                tabNbr[36] = 0;
                tab[36] = 0;
            } else {
                tabNbr[16] -= nombre;
            }
        }
        if (idsac == 6) {
            if (tabNbr[20] - nombre < 1) {
                tabNbr[20] = tabNbr[24];
                tab[20] = tab[24];
                tabNbr[24] = tabNbr[28];
                tab[24] = tab[28];
                tabNbr[28] = tabNbr[32];
                tab[28] = tab[32];
                tabNbr[32] = tabNbr[36];
                tab[32] = tab[36];
                tabNbr[36] = 0;
                tab[36] = 0;
            } else {
                tabNbr[20] -= nombre;
            }
        }
        if (idsac == 7) {
            if (tabNbr[24] - nombre < 1) {
                tabNbr[24] = tabNbr[28];
                tab[24] = tab[28];
                tabNbr[28] = tabNbr[32];
                tab[28] = tab[32];
                tabNbr[32] = tabNbr[36];
                tab[32] = tab[36];
                tabNbr[36] = 0;
                tab[36] = 0;
            } else {
                tabNbr[24] -= nombre;
            }
        }
        if (idsac == 8) {
            if (tabNbr[28] - nombre < 1) {
                tabNbr[28] = tabNbr[32];
                tab[28] = tab[32];
                tabNbr[32] = tabNbr[36];
                tab[32] = tab[36];
                tabNbr[36] = 0;
                tab[36] = 0;
            } else {
                tabNbr[28] -= nombre;
            }
        }
        if (idsac == 9) {
            if (tabNbr[32] - nombre < 1) {
                tabNbr[32] = tabNbr[36];
                tab[32] = tab[36];
                tabNbr[36] = 0;
                tab[36] = 0;
            } else {
                tabNbr[32] -= nombre;
            }
        }
        if (idsac == 10) {
            if (tabNbr[36] - nombre < 1) {
                tabNbr[36] = 0;
                tab[36] = 0;
            }
            tabNbr[36] -= nombre;
        }
    }
    decl String:objets[128];
    Format(objets, 127, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", tabNbr, tab, tabNbr[4], tab[4], tabNbr[8], tab[8], tabNbr[12], tab[12], tabNbr[16], tab[16], tabNbr[20], tab[20], tabNbr[24], tab[24], tabNbr[28], tab[28], tabNbr[32], tab[32], tabNbr[36], tab[36]);
    Format(clientObjetBank[client][0][0], 90, "%s", objets);
    return 0;
}

bool:aLesObjetsEnBank(client, idObjet, nombre)
{
    decl String:split[84][8];
    ExplodeString(clientObjetBank[client][0][0], ",", split, 21, 5);
    decl tab[10];
    tab[0] = StringToInt(split[4], 10);
    tab[4] = StringToInt(split[12], 10);
    tab[8] = StringToInt(split[20], 10);
    tab[12] = StringToInt(split[28], 10);
    tab[16] = StringToInt(split[36], 10);
    tab[20] = StringToInt(split[44], 10);
    tab[24] = StringToInt(split[52], 10);
    tab[28] = StringToInt(split[60], 10);
    tab[32] = StringToInt(split[68], 10);
    tab[36] = StringToInt(split[76], 10);
    decl tabNbr[10];
    tabNbr[0] = StringToInt(split[0][split], 10);
    tabNbr[4] = StringToInt(split[8], 10);
    tabNbr[8] = StringToInt(split[16], 10);
    tabNbr[12] = StringToInt(split[24], 10);
    tabNbr[16] = StringToInt(split[32], 10);
    tabNbr[20] = StringToInt(split[40], 10);
    tabNbr[24] = StringToInt(split[48], 10);
    tabNbr[28] = StringToInt(split[56], 10);
    tabNbr[32] = StringToInt(split[64], 10);
    tabNbr[36] = StringToInt(split[72], 10);
    new bool:existe = 0;
    new i = 0;
    while (i < 10) {
        if (idObjet == tab[i]) {
            existe = 1;
            i++;
        }
        i++;
    }
    if (existe) {
        new k = 0;
        while (k < 10) {
            new var1;
            if (idObjet == tab[k]) {
                return true;
            }
            k++;
        }
    }
    return false;
}

afficherObjetDuSac(client, entity)
{
    if (ProcheJoueurPorte(entity, client)) {
        if (clientNbr1[client][0][0]) {
            new Handle:g_MenuSacBank = CreateMenu(MenuHandler:103, MenuAction:28);
            SetMenuTitle(g_MenuSacBank, "| Quel objets voulez-vous |\n| mettre en banque ? |");
            decl String:buffer[16];
            decl String:InfoObjet[60];
            decl tabObjet[10];
            tabObjet[0] = clientItem1[client][0][0];
            tabObjet[4] = clientItem2[client][0][0];
            tabObjet[8] = clientItem3[client][0][0];
            tabObjet[12] = clientItem4[client][0][0];
            tabObjet[16] = clientItem5[client][0][0];
            tabObjet[20] = clientItem6[client][0][0];
            tabObjet[24] = clientItem7[client][0][0];
            tabObjet[28] = clientItem8[client][0][0];
            tabObjet[32] = clientItem9[client][0][0];
            tabObjet[36] = clientItem10[client][0][0];
            decl tabNbr[10];
            tabNbr[0] = clientNbr1[client][0][0];
            tabNbr[4] = clientNbr2[client][0][0];
            tabNbr[8] = clientNbr3[client][0][0];
            tabNbr[12] = clientNbr4[client][0][0];
            tabNbr[16] = clientNbr5[client][0][0];
            tabNbr[20] = clientNbr6[client][0][0];
            tabNbr[24] = clientNbr7[client][0][0];
            tabNbr[28] = clientNbr8[client][0][0];
            tabNbr[32] = clientNbr9[client][0][0];
            tabNbr[36] = clientNbr10[client][0][0];
            new i = 0;
            while (i < 10) {
                if (tabNbr[i]) {
                    Format(buffer, 16, "%d,%d,%d", i, tabObjet[i], entity);
                    Format(InfoObjet, 60, "%d %s %d:%s", tabNbr[i], objetNom[tabObjet[i]][0][0], objetEffet[tabObjet[i]], objetFonction[tabObjet[i]][0][0]);
                    AddMenuItem(g_MenuSacBank, buffer, InfoObjet, 0);
                    i++;
                }
                i++;
            }
            DisplayMenu(g_MenuSacBank, client, 300);
        } else {
            PrintToChat(client, "%s Vous n'avez pas objets !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockSelectObjetInBank(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[16][12];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 4, 10);
    new idsac = StringToInt(split[0][split], 10) + 1;
    new idObjet = StringToInt(split[4], 10);
    new entity = StringToInt(split[8], 10);
    if (ProcheJoueurPorte(entity, client)) {
        if (idObjet) {
            decl String:titre[60];
            new Handle:g_MenuPoseDobjet = CreateMenu(MenuHandler:95, MenuAction:28);
            Format(titre, 60, "| Combien de : %s |\nVoulez-vous d‚poser ?", objetNom[idObjet][0][0]);
            SetMenuTitle(g_MenuPoseDobjet, titre);
            decl String:para[40];
            decl String:buffer[60];
            Format(para, 40, "1,%d,%d,%d", idObjet, idsac, entity);
            Format(buffer, 60, "Nbr 1 : %s", objetNom[idObjet][0][0]);
            AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
            Format(para, 40, "2,%d,%d,%d", idObjet, idsac, entity);
            Format(buffer, 60, "Nbr 2 : %s", objetNom[idObjet][0][0]);
            AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
            Format(para, 40, "5,%d,%d,%d", idObjet, idsac, entity);
            Format(buffer, 60, "Nbr 5 : %s", objetNom[idObjet][0][0]);
            AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
            Format(para, 40, "10,%d,%d,%d", idObjet, idsac, entity);
            Format(buffer, 60, "Nbr 10 : %s", objetNom[idObjet][0][0]);
            AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
            Format(para, 40, "20,%d,%d,%d", idObjet, idsac, entity);
            Format(buffer, 60, "Nbr 20 : %s", objetNom[idObjet][0][0]);
            AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
            Format(para, 40, "50,%d,%d,%d", idObjet, idsac, entity);
            Format(buffer, 60, "Nbr 50 : %s", objetNom[idObjet][0][0]);
            AddMenuItem(g_MenuPoseDobjet, para, buffer, 0);
            DisplayMenu(g_MenuPoseDobjet, client, 300);
        } else {
            PrintToChat(client, "%s Objets incorrecte ! ", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockPoseAutantDobjet(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[40];
    decl String:split[20][8];
    GetMenuItem(menu, choice, parametre, 40, 0, "", 0);
    ExplodeString(parametre, ",", split, 5, 8);
    new nombre = StringToInt(split[0][split], 10);
    new idObjet = StringToInt(split[4], 10);
    new idsac = StringToInt(split[8], 10);
    new entity = StringToInt(split[12], 10);
    if (ProcheJoueurPorte(entity, client)) {
        if (aLesObjetsEnSac(client, idObjet, nombre)) {
            new place = verifePlaceEnBank(client, idObjet, nombre);
            if (place) {
                remettreOrdreSacPrBank(client, idsac, nombre);
                MettreObjetDansBankNB(client, place, idObjet, nombre);
                PrintToChat(client, "%s %d %s ont etaient ajout‚s en banque !", "[Rp Magnetik : ->]", nombre, objetNom[idObjet][0][0]);
            } else {
                PrintToChat(client, "%s Vous n'avez plus de place en banque !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas %d %s dans votre sac !", "[Rp Magnetik : ->]", nombre, objetNom[idObjet][0][0]);
        }
    } else {
        PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
    }
    return 0;
}

MettreObjetDansBankNB(client, iditem, idobjet, nombre)
{
    decl String:split[84][8];
    ExplodeString(clientObjetBank[client][0][0], ",", split, 21, 5);
    decl tab[10];
    tab[0] = StringToInt(split[4], 10);
    tab[4] = StringToInt(split[12], 10);
    tab[8] = StringToInt(split[20], 10);
    tab[12] = StringToInt(split[28], 10);
    tab[16] = StringToInt(split[36], 10);
    tab[20] = StringToInt(split[44], 10);
    tab[24] = StringToInt(split[52], 10);
    tab[28] = StringToInt(split[60], 10);
    tab[32] = StringToInt(split[68], 10);
    tab[36] = StringToInt(split[76], 10);
    decl tabNbr[10];
    tabNbr[0] = StringToInt(split[0][split], 10);
    tabNbr[4] = StringToInt(split[8], 10);
    tabNbr[8] = StringToInt(split[16], 10);
    tabNbr[12] = StringToInt(split[24], 10);
    tabNbr[16] = StringToInt(split[32], 10);
    tabNbr[20] = StringToInt(split[40], 10);
    tabNbr[24] = StringToInt(split[48], 10);
    tabNbr[28] = StringToInt(split[56], 10);
    tabNbr[32] = StringToInt(split[64], 10);
    tabNbr[36] = StringToInt(split[72], 10);
    if (tabNbr[iditem + -1]) {
        tabNbr[iditem + -1] += nombre;
    } else {
        tabNbr[iditem + -1] = nombre;
        tab[iditem + -1] = idobjet;
    }
    decl String:objets[128];
    Format(objets, 127, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", tabNbr, tab, tabNbr[4], tab[4], tabNbr[8], tab[8], tabNbr[12], tab[12], tabNbr[16], tab[16], tabNbr[20], tab[20], tabNbr[24], tab[24], tabNbr[28], tab[28], tabNbr[32], tab[32], tabNbr[36], tab[36]);
    Format(clientObjetBank[client][0][0], 90, "%s", objets);
    return 0;
}

remettreOrdreSacPrBank(client, idsac, nombre)
{
    if (idsac == 1) {
        if (clientNbr1[client][0][0] - nombre < 1) {
            clientNbr1[client] = clientNbr2[client][0][0];
            clientItem1[client] = clientItem2[client][0][0];
            clientNbr2[client] = clientNbr3[client][0][0];
            clientItem2[client] = clientItem3[client][0][0];
            clientNbr3[client] = clientNbr4[client][0][0];
            clientItem3[client] = clientItem4[client][0][0];
            clientNbr4[client] = clientNbr5[client][0][0];
            clientItem4[client] = clientItem5[client][0][0];
            clientNbr5[client] = clientNbr6[client][0][0];
            clientItem5[client] = clientItem6[client][0][0];
            clientNbr6[client] = clientNbr7[client][0][0];
            clientItem6[client] = clientItem7[client][0][0];
            clientNbr7[client] = clientNbr8[client][0][0];
            clientItem7[client] = clientItem8[client][0][0];
            clientNbr8[client] = clientNbr9[client][0][0];
            clientItem8[client] = clientItem9[client][0][0];
            clientNbr9[client] = clientNbr10[client][0][0];
            clientItem9[client] = clientItem10[client][0][0];
            clientNbr10[client] = 0;
            clientItem10[client] = 0;
        } else {
            new var1 = clientNbr1[client];
            var1 = var1[0][0] - nombre;
        }
    } else {
        if (idsac == 2) {
            if (clientNbr2[client][0][0] - nombre < 1) {
                clientNbr2[client] = clientNbr3[client][0][0];
                clientItem2[client] = clientItem3[client][0][0];
                clientNbr3[client] = clientNbr4[client][0][0];
                clientItem3[client] = clientItem4[client][0][0];
                clientNbr4[client] = clientNbr5[client][0][0];
                clientItem4[client] = clientItem5[client][0][0];
                clientNbr5[client] = clientNbr6[client][0][0];
                clientItem5[client] = clientItem6[client][0][0];
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var2 = clientNbr2[client];
                var2 = var2[0][0] - nombre;
            }
        }
        if (idsac == 3) {
            if (clientNbr3[client][0][0] - nombre < 1) {
                clientNbr3[client] = clientNbr4[client][0][0];
                clientItem3[client] = clientItem4[client][0][0];
                clientNbr4[client] = clientNbr5[client][0][0];
                clientItem4[client] = clientItem5[client][0][0];
                clientNbr5[client] = clientNbr6[client][0][0];
                clientItem5[client] = clientItem6[client][0][0];
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var3 = clientNbr3[client];
                var3 = var3[0][0] - nombre;
            }
        }
        if (idsac == 4) {
            if (clientNbr4[client][0][0] - nombre < 1) {
                clientNbr4[client] = clientNbr5[client][0][0];
                clientItem4[client] = clientItem5[client][0][0];
                clientNbr5[client] = clientNbr6[client][0][0];
                clientItem5[client] = clientItem6[client][0][0];
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var4 = clientNbr4[client];
                var4 = var4[0][0] - nombre;
            }
        }
        if (idsac == 5) {
            if (clientNbr5[client][0][0] - nombre < 1) {
                clientNbr5[client] = clientNbr6[client][0][0];
                clientItem5[client] = clientItem6[client][0][0];
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var5 = clientNbr5[client];
                var5 = var5[0][0] - nombre;
            }
        }
        if (idsac == 6) {
            if (clientNbr6[client][0][0] - nombre < 1) {
                clientNbr6[client] = clientNbr7[client][0][0];
                clientItem6[client] = clientItem7[client][0][0];
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var6 = clientNbr6[client];
                var6 = var6[0][0] - nombre;
            }
        }
        if (idsac == 7) {
            if (clientNbr7[client][0][0] - nombre < 1) {
                clientNbr7[client] = clientNbr8[client][0][0];
                clientItem7[client] = clientItem8[client][0][0];
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var7 = clientNbr7[client];
                var7 = var7[0][0] - nombre;
            }
        }
        if (idsac == 8) {
            if (clientNbr8[client][0][0] - nombre < 1) {
                clientNbr8[client] = clientNbr9[client][0][0];
                clientItem8[client] = clientItem9[client][0][0];
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var8 = clientNbr8[client];
                var8 = var8[0][0] - nombre;
            }
        }
        if (idsac == 9) {
            if (clientNbr9[client][0][0] - nombre < 1) {
                clientNbr9[client] = clientNbr10[client][0][0];
                clientItem9[client] = clientItem10[client][0][0];
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            } else {
                new var9 = clientNbr9[client];
                var9 = var9[0][0] - nombre;
            }
        }
        if (idsac == 10) {
            if (clientNbr10[client][0][0] - nombre < 1) {
                clientNbr10[client] = 0;
                clientItem10[client] = 0;
            }
            new var10 = clientNbr10[client];
            var10 = var10[0][0] - nombre;
        }
    }
    return 0;
}

verifePlaceEnBank(client, idObjet, nombre)
{
    decl String:split[84][8];
    ExplodeString(clientObjetBank[client][0][0], ",", split, 21, 5);
    decl tab[10];
    tab[0] = StringToInt(split[4], 10);
    tab[4] = StringToInt(split[12], 10);
    tab[8] = StringToInt(split[20], 10);
    tab[12] = StringToInt(split[28], 10);
    tab[16] = StringToInt(split[36], 10);
    tab[20] = StringToInt(split[44], 10);
    tab[24] = StringToInt(split[52], 10);
    tab[28] = StringToInt(split[60], 10);
    tab[32] = StringToInt(split[68], 10);
    tab[36] = StringToInt(split[76], 10);
    decl tabNbr[10];
    tabNbr[0] = StringToInt(split[0][split], 10);
    tabNbr[4] = StringToInt(split[8], 10);
    tabNbr[8] = StringToInt(split[16], 10);
    tabNbr[12] = StringToInt(split[24], 10);
    tabNbr[16] = StringToInt(split[32], 10);
    tabNbr[20] = StringToInt(split[40], 10);
    tabNbr[24] = StringToInt(split[48], 10);
    tabNbr[28] = StringToInt(split[56], 10);
    tabNbr[32] = StringToInt(split[64], 10);
    tabNbr[36] = StringToInt(split[72], 10);
    new valeur = 0;
    new bool:existe = 0;
    new i = 0;
    while (i < 10) {
        if (idObjet == tab[i]) {
            existe = 1;
            i++;
        }
        i++;
    }
    if (existe) {
        new k = 0;
        while (k < 10) {
            new var1;
            if (idObjet == tab[k]) {
                valeur = k + 1;
                return valeur;
            }
            k++;
        }
    } else {
        new j = 0;
        while (j < 10) {
            if (tab[j]) {
                j++;
            } else {
                valeur = j + 1;
                return valeur;
            }
            j++;
        }
    }
    return valeur;
}

bool:aLesObjetsEnSac(client, idObjet, nombre)
{
    decl tab[10];
    tab[0] = clientItem1[client][0][0];
    tab[4] = clientItem2[client][0][0];
    tab[8] = clientItem3[client][0][0];
    tab[12] = clientItem4[client][0][0];
    tab[16] = clientItem5[client][0][0];
    tab[20] = clientItem6[client][0][0];
    tab[24] = clientItem7[client][0][0];
    tab[28] = clientItem8[client][0][0];
    tab[32] = clientItem9[client][0][0];
    tab[36] = clientItem10[client][0][0];
    decl tabNbr[10];
    tabNbr[0] = clientNbr1[client][0][0];
    tabNbr[4] = clientNbr2[client][0][0];
    tabNbr[8] = clientNbr3[client][0][0];
    tabNbr[12] = clientNbr4[client][0][0];
    tabNbr[16] = clientNbr5[client][0][0];
    tabNbr[20] = clientNbr6[client][0][0];
    tabNbr[24] = clientNbr7[client][0][0];
    tabNbr[28] = clientNbr8[client][0][0];
    tabNbr[32] = clientNbr9[client][0][0];
    tabNbr[36] = clientNbr10[client][0][0];
    new bool:existe = 0;
    new i = 0;
    while (i < 10) {
        if (idObjet == tab[i]) {
            existe = 1;
            i++;
        }
        i++;
    }
    if (existe) {
        new k = 0;
        while (k < 10) {
            new var1;
            if (idObjet == tab[k]) {
                return true;
            }
            k++;
        }
    }
    return false;
}

public BlockpanelRetirBank(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[12][16];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 16);
    new num = StringToInt(split[0][split], 10);
    new entity = StringToInt(split[4], 10);
    if (ProcheJoueurPorte(entity, client)) {
        if (num == 1) {
            RetirArgentEnBanque(client, 100);
        } else {
            if (num == 2) {
                RetirArgentEnBanque(client, 200);
            }
            if (num == 3) {
                RetirArgentEnBanque(client, 500);
            }
            if (num == 4) {
                RetirArgentEnBanque(client, 1000);
            }
            if (num == 5) {
                RetirArgentEnBanque(client, 2000);
            }
            if (num == 6) {
                RetirArgentEnBanque(client, 5000);
            }
            if (num == 7) {
                RetirArgentEnBanque(client, -1);
            }
        }
    } else {
        PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelDepoBank(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[12][16];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 16);
    new num = StringToInt(split[0][split], 10);
    new entity = StringToInt(split[4], 10);
    if (ProcheJoueurPorte(entity, client)) {
        if (num == 1) {
            DepoArgentEnBanque(client, 100);
        } else {
            if (num == 2) {
                DepoArgentEnBanque(client, 200);
            }
            if (num == 3) {
                DepoArgentEnBanque(client, 500);
            }
            if (num == 4) {
                DepoArgentEnBanque(client, 1000);
            }
            if (num == 5) {
                DepoArgentEnBanque(client, 2000);
            }
            if (num == 6) {
                DepoArgentEnBanque(client, 5000);
            }
            if (num == 7) {
                DepoArgentEnBanque(client, -1);
            }
        }
    } else {
        PrintToChat(client, "%s Vous ‚tes trop loin du distributeur", "[Rp Magnetik : ->]");
    }
    return 0;
}

DepoArgentEnBanque(client, valeur)
{
    if (valeur == -1) {
        new argent = clientCash[client][0][0];
        if (0 < argent) {
            clientCash[client] = 0;
            new var1 = clientBank[client];
            var1 = var1[0][0] + argent;
            PrintToChat(client, "%s Transaction valider !", "[Rp Magnetik : ->]");
        } else {
            PrintToChat(client, "%s Vous n'avez plus d'argent !", "[Rp Magnetik : ->]");
        }
    } else {
        new argent = clientCash[client][0][0];
        if (argent >= valeur) {
            new var2 = clientCash[client];
            var2 = var2[0][0] - valeur;
            new var3 = clientBank[client];
            var3 = var3[0][0] + valeur;
        } else {
            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

RetirArgentEnBanque(client, valeur)
{
    if (valeur == -1) {
        new argent = clientBank[client][0][0];
        if (0 < argent) {
            clientBank[client] = 0;
            new var1 = clientCash[client];
            var1 = var1[0][0] + argent;
            PrintToChat(client, "%s Transaction valider !", "[Rp Magnetik : ->]");
        } else {
            PrintToChat(client, "%s Vous n'avez plus d'argent !", "[Rp Magnetik : ->]");
        }
    } else {
        new argent = clientBank[client][0][0];
        if (argent >= valeur) {
            new var2 = clientBank[client];
            var2 = var2[0][0] - valeur;
            new var3 = clientCash[client];
            var3 = var3[0][0] + valeur;
        } else {
            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

LouerUnCommerce(client, index, nbrJour)
{
    if (!DetientUnMagasin(client)) {
        new SonIdMetier = clientIdMetier[client][0][0];
        if (index == 56) {
            if (SonIdMetier == 9) {
                if (PasDeProProprietaire(index)) {
                    new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                    if (compte) {
                        if (compte == 1) {
                            new var1 = clientCash[client];
                            var1 = var1[0][0] - nbrJour * portePrix[index][0][0];
                            DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                            donnerCleDUnCommerce(client, index, nbrJour);
                            PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de la pizzeria pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                            sauvegarderInfosClient(client);
                        } else {
                            if (compte == 2) {
                                new var2 = clientBank[client];
                                var2 = var2[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de la pizzeria pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            }
                            return 0;
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il y a d‚j… un propri‚taire … la pizzeria *NPC Principal", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Il faut ˆtre chef pizzeria pour louer ce restaurant *NPC Principal", "[Rp Magnetik : ->]");
            }
        } else {
            if (index == 16) {
                if (SonIdMetier == 13) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var3 = clientCash[client];
                                var3 = var3[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de la banque pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var4 = clientBank[client];
                                    var4 = var4[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de la banque pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire … la banque *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef banquier pour achet‚ cet banque *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 4) {
                if (SonIdMetier == 17) {
                    if (nbrJour * portePrix[index][0][0] <= clientCash[client][0][0]) {
                        if (PasDeProProprietaire(index)) {
                            new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                            if (compte) {
                                if (compte == 1) {
                                    new var5 = clientCash[client];
                                    var5 = var5[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de l'epicerie pendant %d jours*NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                } else {
                                    if (compte == 2) {
                                        new var6 = clientBank[client];
                                        var6 = var6[0][0] - nbrJour * portePrix[index][0][0];
                                        DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                        donnerCleDUnCommerce(client, index, nbrJour);
                                        PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de l'epicerie pendant %d jours*NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                        sauvegarderInfosClient(client);
                                    }
                                    return 0;
                                }
                            } else {
                                PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                            }
                        } else {
                            PrintToChat(client, "%s Il y a d‚j… un propri‚taire … l'epicerie *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Vous ne pouvez pa louer ce magasin, car vous n'avez pas assez d'argent *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef Coutelier pour louer cet epicerie *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 10) {
                if (SonIdMetier == 27) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var7 = clientCash[client];
                                var7 = var7[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du Bar pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var8 = clientBank[client];
                                    var8 = var8[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du Bar pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire au Bar !*NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef barman pour louer ce bar *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 12) {
                if (SonIdMetier == 25) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var9 = clientCash[client];
                                var9 = var9[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de Ikea pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var10 = clientBank[client];
                                    var10 = var10[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de Ikea pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire … Ikea *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef vendeur Ikea pour louer ce commerce *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 32) {
                if (SonIdMetier == 31) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var11 = clientCash[client];
                                var11 = var11[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de Ebay pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var12 = clientBank[client];
                                    var12 = var12[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de Ebay pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire … Ebay *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef stysliste pour louer ce commerce *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 33) {
                if (SonIdMetier == 29) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var13 = clientCash[client];
                                var13 = var13[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de Microshop pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var14 = clientBank[client];
                                    var14 = var14[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de Microshop pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire … Microshop *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef dealer pour louer ce commerce *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 37) {
                if (SonIdMetier == 11) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var15 = clientCash[client];
                                var15 = var15[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du Stand de tir pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var16 = clientBank[client];
                                    var16 = var16[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du Stand de tir pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire au Stand de tir *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef moniteur de tir pour louer ce commerce *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 41) {
                if (PasDeProProprietaire(index)) {
                    new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                    if (compte) {
                        if (compte == 1) {
                            new var17 = clientCash[client];
                            var17 = var17[0][0] - nbrJour * portePrix[index][0][0];
                            DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                            donnerCleDUnCommerce(client, index, nbrJour);
                            PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du garage Chop Shop pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                            sauvegarderInfosClient(client);
                        } else {
                            if (compte == 2) {
                                new var18 = clientBank[client];
                                var18 = var18[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du garage Chop Shop pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            }
                            return 0;
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il y a d‚j… un propri‚taire au garage Chop Shop *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 42) {
                if (SonIdMetier == 19) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var19 = clientCash[client];
                                var19 = var19[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de l'armurie pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var20 = clientBank[client];
                                    var20 = var20[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de l'armurie pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire … l'armurie *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef armurier pour louer ce commerce *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 47) {
                if (SonIdMetier == 21) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var21 = clientCash[client];
                                var21 = var21[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du Seven pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var22 = clientBank[client];
                                    var22 = var22[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du Seven pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire au Seven *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre chef en Explosif pour louer ce commerce *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 97) {
                if (SonIdMetier == 6) {
                    if (PasDeProProprietaire(index)) {
                        new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                        if (compte) {
                            if (compte == 1) {
                                new var23 = clientCash[client];
                                var23 = var23[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de l'hopital pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            } else {
                                if (compte == 2) {
                                    new var24 = clientBank[client];
                                    var24 = var24[0][0] - nbrJour * portePrix[index][0][0];
                                    DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                    donnerCleDUnCommerce(client, index, nbrJour);
                                    PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire de l'hopital pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                    sauvegarderInfosClient(client);
                                }
                                return 0;
                            }
                        } else {
                            PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                        }
                    } else {
                        PrintToChat(client, "%s Il y a d‚j… un propri‚taire … l'hopital *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il faut ˆtre Directeur hopital pour louer ce commerce *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (index == 70) {
                if (PasDeProProprietaire(index)) {
                    new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                    if (compte) {
                        if (compte == 1) {
                            new var25 = clientCash[client];
                            var25 = var25[0][0] - nbrJour * portePrix[index][0][0];
                            DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                            donnerCleDUnCommerce(client, index, nbrJour);
                            PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du Carshop pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                            sauvegarderInfosClient(client);
                        } else {
                            if (compte == 2) {
                                new var26 = clientBank[client];
                                var26 = var26[0][0] - nbrJour * portePrix[index][0][0];
                                DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                                donnerCleDUnCommerce(client, index, nbrJour);
                                PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire du Carshop pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", nbrJour);
                                sauvegarderInfosClient(client);
                            }
                            return 0;
                        }
                    } else {
                        PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Il y a d‚j… un propri‚taire au Carshop *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            PrintToChat(client, "%s Magasin non … louer !*NPC Principal", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous d‚tenez d‚j… un commerce donc vous pouvez plus en louer ! *NPC Principal", "[Rp Magnetik : ->]");
    }
    return 0;
}

donnerCleDUnCommerce(client, index, nbrJour)
{
    decl String:clientName[32];
    GetClientName(client, clientName, 32);
    decl String:steamTarget[32];
    GetClientAuthString(client, steamTarget, 32);
    if (index == 56) {
        new i = 0;
        while (i < 4) {
            ajouterNouveauProprietaire(1, listPortePizzeria[i][0][0], steamTarget, clientName);
            i++;
        }
        LocationDunPorte(56, nbrJour);
    } else {
        if (index == 4) {
            ajouterNouveauProprietaire(1, index, steamTarget, clientName);
            LocationDunPorte(4, nbrJour);
        }
        if (index == 10) {
            new i = 0;
            while (i < 3) {
                ajouterNouveauProprietaire(1, listPorteBar[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(10, nbrJour);
        }
        if (index == 12) {
            new i = 0;
            while (i < 3) {
                ajouterNouveauProprietaire(1, listPorteIkea[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(12, nbrJour);
        }
        if (index == 32) {
            ajouterNouveauProprietaire(1, index, steamTarget, clientName);
            LocationDunPorte(32, nbrJour);
        }
        if (index == 33) {
            ajouterNouveauProprietaire(1, index, steamTarget, clientName);
            LocationDunPorte(33, nbrJour);
        }
        if (index == 37) {
            new i = 0;
            while (i < 3) {
                ajouterNouveauProprietaire(1, listPorteMoniteurTir[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(37, nbrJour);
        }
        if (index == 41) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteGarage[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(41, nbrJour);
        }
        if (index == 42) {
            new i = 0;
            while (i < 5) {
                ajouterNouveauProprietaire(1, listPorteArmurie[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(42, nbrJour);
        }
        if (index == 47) {
            new i = 0;
            while (i < 3) {
                ajouterNouveauProprietaire(1, listPorteSeven[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(47, nbrJour);
        }
        if (index == 97) {
            new i = 0;
            while (i < 8) {
                ajouterNouveauProprietaire(1, listPorteHopital[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(97, nbrJour);
        }
        if (index == 70) {
            new i = 0;
            while (i < 6) {
                ajouterNouveauProprietaire(1, listPorteCarshop[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(70, nbrJour);
        }
        if (index == 16) {
            new i = 0;
            while (i < 3) {
                ajouterNouveauProprietaire(1, lsitPorteBank[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(16, nbrJour);
        }
    }
    return 0;
}

LocationDunPorte(index, nbrJour)
{
    new temps = nbrJour * 86400;
    decl String:rek[512];
    Format(rek, 512, "UPDATE Porte SET location = %d WHERE id_porte = %d", temps, index);
    if (!SQL_FastQuery(db, rek, -1)) {
        decl String:error[256];
        SQL_GetError(db, error, 255);
        Log("RolePlay Admin", "impossible de update location (LocationDunPorte) magasin.sp -> erreur : %s", error);
        return 0;
    }
    porteLocation[index] = temps;
    return 0;
}

VerificationLocation()
{
    if (minute == 240) {
        new index = 0;
        while (index < 13) {
            if (!PasDeProProprietaire(listMagasin[index][0][0])) {
                if (porteLocation[listMagasin[index][0][0]][0][0] > 1) {
                    new var1 = porteLocation[listMagasin[index][0][0]];
                    var1 = var1[0][0] + -1440;
                    decl String:rek[512];
                    Format(rek, 512, "UPDATE Porte SET location = %d WHERE id_porte = %d", porteLocation[listMagasin[index][0][0]], listMagasin[index]);
                    if (!SQL_FastQuery(db, rek, -1)) {
                        decl String:error[256];
                        SQL_GetError(db, error, 255);
                        Log("RolePlay Admin", "impossible de update porte location magasin.sp -> erreur : %s", error);
                        index++;
                    }
                    index++;
                }
                porteLocation[listMagasin[index][0][0]] = 0;
                FinDeLocationUnMagasin(listMagasin[index][0][0]);
                index++;
            }
            index++;
        }
    }
    return 0;
}

bool:DetientUnMagasin(client)
{
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new i = 0;
    while (i < 13) {
        if (StrEqual(porteProprio1[listMagasin[i][0][0]][0][0], steamid, true)) {
            return true;
        }
        i++;
    }
    return false;
}

bool:PasDeProProprietaire(index)
{
    if (StrEqual(porteProprio1[index][0][0], "Aucun", true)) {
        return true;
    }
    return false;
}

NumeroDuMagasinDetenu(client)
{
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new i = 0;
    while (i < 13) {
        if (StrEqual(porteProprio1[listMagasin[i][0][0]][0][0], steamid, true)) {
            return listMagasin[i][0][0];
        }
        i++;
    }
    return -1;
}

FinDeLocationUnMagasin(index)
{
    if (index == 56) {
        new i = 0;
        while (i < 4) {
            RetirerToutLesProprietaire(listPortePizzeria[i][0][0]);
            i++;
        }
    } else {
        if (index == 4) {
            RetirerToutLesProprietaire(index);
        }
        if (index == 10) {
            new i = 0;
            while (i < 3) {
                RetirerToutLesProprietaire(listPorteBar[i][0][0]);
                i++;
            }
        }
        if (index == 12) {
            new i = 0;
            while (i < 3) {
                RetirerToutLesProprietaire(listPorteIkea[i][0][0]);
                i++;
            }
        }
        if (index == 32) {
            RetirerToutLesProprietaire(index);
        }
        if (index == 33) {
            RetirerToutLesProprietaire(index);
        }
        if (index == 37) {
            new i = 0;
            while (i < 3) {
                RetirerToutLesProprietaire(listPorteMoniteurTir[i][0][0]);
                i++;
            }
        }
        if (index == 41) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteGarage[i][0][0]);
                i++;
            }
        }
        if (index == 42) {
            new i = 0;
            while (i < 5) {
                RetirerToutLesProprietaire(listPorteArmurie[i][0][0]);
                i++;
            }
        }
        if (index == 47) {
            new i = 0;
            while (i < 3) {
                RetirerToutLesProprietaire(listPorteSeven[i][0][0]);
                i++;
            }
        }
        if (index == 97) {
            new i = 0;
            while (i < 8) {
                RetirerToutLesProprietaire(listPorteHopital[i][0][0]);
                i++;
            }
        }
        if (index == 70) {
            new i = 0;
            while (i < 6) {
                RetirerToutLesProprietaire(listPorteCarshop[i][0][0]);
                i++;
            }
        }
        if (index == 16) {
            new i = 0;
            while (i < 3) {
                RetirerToutLesProprietaire(lsitPorteBank[i][0][0]);
                i++;
            }
        }
    }
    return 0;
}

LouerUnAppart(client, index, nbrJour)
{
    if (VerificationAppart(index)) {
        if (!DetientUnAppartement(client)) {
            if (PasDeProProprietaire(index)) {
                new compte = verifieAsseArgent(client, nbrJour * portePrix[index][0][0]);
                if (compte) {
                    if (compte == 1) {
                        new var1 = clientCash[client];
                        var1 = var1[0][0] - nbrJour * portePrix[index][0][0];
                        DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                        donnerCleDUnAppart(client, index, nbrJour);
                        PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire le appart : %s pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", porteNom[index][0][0], nbrJour);
                        sauvegarderInfosClient(client);
                    } else {
                        if (compte == 2) {
                            new var2 = clientBank[client];
                            var2 = var2[0][0] - nbrJour * portePrix[index][0][0];
                            DonnerArgentALaTG(nbrJour * portePrix[index][0][0]);
                            donnerCleDUnAppart(client, index, nbrJour);
                            PrintToChat(client, "%s F‚licitations vous ˆtes propri‚taire le appart : %s pendant %d jours *NPC Principal", "[Rp Magnetik : ->]", porteNom[index][0][0], nbrJour);
                            sauvegarderInfosClient(client);
                        }
                        return 0;
                    }
                } else {
                    PrintToChat(client, "%s Vous n'avez pas assez d'argent ! *NPC Principal", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Il y a d‚j… un propri‚taire … la pizzeria *NPC Principal", "[Rp Magnetik : ->]");
            }
        }
        PrintToChat(client, "%s Vous d‚tenez d‚j… un appartement donc vous pouvez plus en louer ! *NPC Principal", "[Rp Magnetik : ->]");
    }
    return 0;
}

VerificationLocationAppartement()
{
    if (minute == 300) {
        new index = 0;
        while (index < 18) {
            if (!PasDeProProprietaire(listAppartPrincipal[index][0][0])) {
                if (porteLocation[listAppartPrincipal[index][0][0]][0][0] > 1) {
                    new var1 = porteLocation[listAppartPrincipal[index][0][0]];
                    var1 = var1[0][0] + -1440;
                    decl String:rek[512];
                    Format(rek, 512, "UPDATE Porte SET location = %d WHERE id_porte = %d", porteLocation[listAppartPrincipal[index][0][0]], listAppartPrincipal[index]);
                    if (!SQL_FastQuery(db, rek, -1)) {
                        decl String:error[256];
                        SQL_GetError(db, error, 255);
                        Log("RolePlay Admin", "impossible de update porte location appartement.sp -> erreur : %s", error);
                        index++;
                    }
                    index++;
                }
                porteLocation[listAppartPrincipal[index][0][0]] = 0;
                FindeLocationAppartment(listAppartPrincipal[index][0][0]);
                index++;
            }
            index++;
        }
    }
    return 0;
}

donnerCleDUnAppart(client, index, nbrJour)
{
    decl String:clientName[32];
    GetClientName(client, clientName, 32);
    decl String:steamTarget[32];
    GetClientAuthString(client, steamTarget, 32);
    if (index) {
        if (index == 5) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listEpicAppartP1[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(5, nbrJour);
        }
        if (index == 8) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listEpicAppartP2[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(8, nbrJour);
        }
        if (index == 21) {
            new i = 0;
            while (i < 4) {
                ajouterNouveauProprietaire(1, listAH1[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(21, nbrJour);
        }
        if (index == 88) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listARDH[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(88, nbrJour);
        }
        if (index == 90) {
            new i = 0;
            while (i < 3) {
                ajouterNouveauProprietaire(1, listApremier[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(90, nbrJour);
        }
        if (index == 93) {
            new i = 0;
            while (i < 3) {
                ajouterNouveauProprietaire(1, listAdeux[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(93, nbrJour);
        }
        if (index == 96) {
            ajouterNouveauProprietaire(1, 96, steamTarget, clientName);
            LocationDunPorte(96, nbrJour);
        }
        if (index == 108) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP1[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(108, nbrJour);
        }
        if (index == 110) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP2[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(110, nbrJour);
        }
        if (index == 112) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP3[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(112, nbrJour);
        }
        if (index == 114) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP4[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(114, nbrJour);
        }
        if (index == 116) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP5[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(116, nbrJour);
        }
        if (index == 118) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP6[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(118, nbrJour);
        }
        if (index == 120) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP7[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(120, nbrJour);
        }
        if (index == 122) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP8[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(122, nbrJour);
        }
        if (index == 124) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP9[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(124, nbrJour);
        }
        if (index == 126) {
            new i = 0;
            while (i < 2) {
                ajouterNouveauProprietaire(1, listPorteHoteP10[i][0][0], steamTarget, clientName);
                i++;
            }
            LocationDunPorte(126, nbrJour);
        }
    } else {
        new i = 0;
        while (i < 4) {
            ajouterNouveauProprietaire(1, listAH2[i][0][0], steamTarget, clientName);
            i++;
        }
        LocationDunPorte(0, nbrJour);
    }
    return 0;
}

NumeroDeAppartDetenu(client)
{
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new i = 0;
    while (i < 18) {
        if (StrEqual(porteProprio1[listAppartPrincipal[i][0][0]][0][0], steamid, true)) {
            return listAppartPrincipal[i][0][0];
        }
        i++;
    }
    return -1;
}

bool:DetientUnAppartement(client)
{
    decl String:steamid[32];
    GetClientAuthString(client, steamid, 32);
    new i = 0;
    while (i < 18) {
        if (StrEqual(porteProprio1[listAppartPrincipal[i][0][0]][0][0], steamid, true)) {
            return true;
        }
        i++;
    }
    return false;
}

bool:VerificationAppart(index)
{
    new i = 0;
    while (i < 18) {
        if (index == listAppartPrincipal[i][0][0]) {
            return true;
        }
        i++;
    }
    return false;
}

FindeLocationAppartment(index)
{
    if (index) {
        if (index == 5) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listEpicAppartP1[i][0][0]);
                i++;
            }
        }
        if (index == 8) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listEpicAppartP2[i][0][0]);
                i++;
            }
        }
        if (index == 21) {
            new i = 0;
            while (i < 4) {
                RetirerToutLesProprietaire(listAH1[i][0][0]);
                i++;
            }
        }
        if (index == 88) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listARDH[i][0][0]);
                i++;
            }
        }
        if (index == 90) {
            new i = 0;
            while (i < 3) {
                RetirerToutLesProprietaire(listApremier[i][0][0]);
                i++;
            }
        }
        if (index == 93) {
            new i = 0;
            while (i < 3) {
                RetirerToutLesProprietaire(listAdeux[i][0][0]);
                i++;
            }
        }
        if (index == 96) {
            RetirerToutLesProprietaire(index);
        }
        if (index == 108) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP1[i][0][0]);
                i++;
            }
        }
        if (index == 110) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP2[i][0][0]);
                i++;
            }
        }
        if (index == 112) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP3[i][0][0]);
                i++;
            }
        }
        if (index == 114) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP4[i][0][0]);
                i++;
            }
        }
        if (index == 116) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP5[i][0][0]);
                i++;
            }
        }
        if (index == 118) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP6[i][0][0]);
                i++;
            }
        }
        if (index == 120) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP7[i][0][0]);
                i++;
            }
        }
        if (index == 122) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP8[i][0][0]);
                i++;
            }
        }
        if (index == 124) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP9[i][0][0]);
                i++;
            }
        }
        if (index == 126) {
            new i = 0;
            while (i < 2) {
                RetirerToutLesProprietaire(listPorteHoteP10[i][0][0]);
                i++;
            }
        }
    } else {
        new i = 0;
        while (i < 4) {
            RetirerToutLesProprietaire(listAH2[i][0][0]);
            i++;
        }
    }
    return 0;
}

affichageMenuDistriBoisson(client, entity)
{
    if (ProcheJoueurPorte(entity, client)) {
        new Handle:g_MenuDistriBoisson = CreateMenu(MenuHandler:57, MenuAction:28);
        SetMenuTitle(g_MenuDistriBoisson, "| Distributeur de boisson |\n Quel boisson voulez-vous acheter ?");
        decl String:buffer[16];
        decl String:InfoObjet[60];
        new i = 0;
        while (i < 9) {
            Format(buffer, 16, "%d,%d", listBoisson[i], entity);
            Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[listBoisson[i][0][0]][0][0], objetEffet[listBoisson[i][0][0]], objetFonction[listBoisson[i][0][0]][0][0], objetPrix[listBoisson[i][0][0]][0][0] * 3);
            AddMenuItem(g_MenuDistriBoisson, buffer, InfoObjet, 0);
            i++;
        }
        DisplayMenu(g_MenuDistriBoisson, client, 300);
    }
    return 0;
}

public BlockMenuDistriBoisson(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[12][16];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 16);
    new idObjet = StringToInt(split[0][split], 10);
    new entity = StringToInt(split[4], 10);
    if (ProcheJoueurPorte(entity, client)) {
        new cash = clientCash[client][0][0];
        if (objetPrix[idObjet][0][0] * 3 <= cash) {
            new place = TrouverPlaceDansSac(client, idObjet);
            if (0 < place) {
                DonneLargentAuProprietaire(entity, idObjet);
                new var1 = clientCash[client];
                var1 = var1[0][0] - objetPrix[idObjet][0][0] * 3;
                MettreObjetDansSac(client, place, idObjet);
                PrintToChat(client, "%s Votre boisson est dans votre sac !", "[Rp Magnetik : ->]");
            } else {
                PrintToChat(client, "%s Vous n'avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du distributeur de boisson !", "[Rp Magnetik : ->]");
    }
    return 0;
}

DonneLargentAuProprietaire(entity, idObjet)
{
    if (entity == 746) {
        if (!PasDeProProprietaire(12)) {
            decl String:steamid[32];
            strcopy(steamid, 32, porteProprio1[48][0]);
            decl String:clientSteamId[32];
            new client = 1;
            while (client <= MaxClients) {
                new var1;
                if (IsClientInGame(client)) {
                    GetClientAuthString(client, clientSteamId, 32);
                    if (StrEqual(clientSteamId, steamid, true)) {
                        new var6 = clientCash[client];
                        var6 = objetPrix[idObjet][0][0] + var6[0][0];
                        PrintToChat(client, "%s Votre distributeur … vendu %d $ de boisson !", "[Rp Magnetik : ->]", objetPrix[idObjet]);
                        client++;
                    }
                    client++;
                }
                client++;
            }
        }
    } else {
        if (entity == 628) {
            if (!PasDeProProprietaire(4)) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[16][0]);
                decl String:clientSteamId[32];
                new client = 1;
                while (client <= MaxClients) {
                    new var2;
                    if (IsClientInGame(client)) {
                        GetClientAuthString(client, clientSteamId, 32);
                        if (StrEqual(clientSteamId, steamid, true)) {
                            new var7 = clientCash[client];
                            var7 = objetPrix[idObjet][0][0] + var7[0][0];
                            PrintToChat(client, "%s Votre distributeur … vendu %d $ de boisson !", "[Rp Magnetik : ->]", objetPrix[idObjet]);
                            client++;
                        }
                        client++;
                    }
                    client++;
                }
            }
        }
        if (entity == 922) {
            if (!PasDeProProprietaire(82)) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[328][0]);
                decl String:clientSteamId[32];
                new client = 1;
                while (client <= MaxClients) {
                    new var3;
                    if (IsClientInGame(client)) {
                        GetClientAuthString(client, clientSteamId, 32);
                        if (StrEqual(clientSteamId, steamid, true)) {
                            new var8 = clientCash[client];
                            var8 = objetPrix[idObjet][0][0] + var8[0][0];
                            PrintToChat(client, "%s Votre distributeur … vendu %d $ de boisson !", "[Rp Magnetik : ->]", objetPrix[idObjet]);
                            client++;
                        }
                        client++;
                    }
                    client++;
                }
            }
        }
        if (entity == 1304) {
            if (!PasDeProProprietaire(49)) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[196][0]);
                decl String:clientSteamId[32];
                new client = 1;
                while (client <= MaxClients) {
                    new var4;
                    if (IsClientInGame(client)) {
                        GetClientAuthString(client, clientSteamId, 32);
                        if (StrEqual(clientSteamId, steamid, true)) {
                            new var9 = clientCash[client];
                            var9 = objetPrix[idObjet][0][0] + var9[0][0];
                            PrintToChat(client, "%s Votre distributeur … vendu %d $ de boisson !", "[Rp Magnetik : ->]", objetPrix[idObjet]);
                            client++;
                        }
                        client++;
                    }
                    client++;
                }
            }
        }
        if (entity == 329) {
            if (!PasDeProProprietaire(97)) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[388][0]);
                decl String:clientSteamId[32];
                new client = 1;
                while (client <= MaxClients) {
                    new var5;
                    if (IsClientInGame(client)) {
                        GetClientAuthString(client, clientSteamId, 32);
                        if (StrEqual(clientSteamId, steamid, true)) {
                            new var10 = clientCash[client];
                            var10 = objetPrix[idObjet][0][0] + var10[0][0];
                            PrintToChat(client, "%s Votre distributeur … vendu %d $ de boisson !", "[Rp Magnetik : ->]", objetPrix[idObjet]);
                            client++;
                        }
                        client++;
                    }
                    client++;
                }
            }
        }
    }
    return 0;
}

affichageMenuNPC(client, entity)
{
    if (ProcheJoueurPorte(entity, client)) {
        if (entity == 1312) {
            new Handle:g_MenuNPCARmurier = CreateMenu(MenuHandler:75, MenuAction:28);
            SetMenuTitle(g_MenuNPCARmurier, "| NPC Armurier |\nQuel arme d‚sirez-vous acheter ?");
            decl String:buffer[16];
            decl String:InfoObjet[60];
            new i = 0;
            while (i < 84) {
                if (objetIdAssoc[i][0][0] == 19) {
                    Format(buffer, 16, "%d,%d", i, entity);
                    Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i][0][0] * 20 / 100 + objetPrix[i][0][0]);
                    AddMenuItem(g_MenuNPCARmurier, buffer, InfoObjet, 0);
                    i++;
                }
                i++;
            }
            DisplayMenu(g_MenuNPCARmurier, client, 300);
        }
        if (entity == 1309) {
            new Handle:g_MenuNPCMonit = CreateMenu(MenuHandler:73, MenuAction:28);
            SetMenuTitle(g_MenuNPCMonit, "| NPC Moniteur de Tir |\nQuel d‚sirez-vous ?");
            decl String:buffer[16];
            decl String:InfoObjet[60];
            Format(buffer, 16, "1,%d", entity);
            AddMenuItem(g_MenuNPCMonit, buffer, "Port d'arme secondaire 3000$", 0);
            Format(buffer, 16, "2,%d", entity);
            AddMenuItem(g_MenuNPCMonit, buffer, "Port d'arme primaire 4200$", 0);
            Format(buffer, 16, "3,%d", entity);
            AddMenuItem(g_MenuNPCMonit, buffer, "Pr‚cision de tir 36$/unite", 0);
            new i = 1;
            while (i < 84) {
                if (objetIdAssoc[i][0][0] == 11) {
                    Format(buffer, 16, "%d,%d", i, entity);
                    Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i][0][0] * 20 / 100 + objetPrix[i][0][0]);
                    AddMenuItem(g_MenuNPCMonit, buffer, InfoObjet, 0);
                    i++;
                }
                i++;
            }
            DisplayMenu(g_MenuNPCMonit, client, 300);
        }
        if (entity == 1324) {
            new sonIdMetier = clientIdMetier[client][0][0];
            if (!inList(sonIdMetier, listIntChangSkins, 5)) {
                new Handle:g_MenuNPCEbay = CreateMenu(MenuHandler:75, MenuAction:28);
                SetMenuTitle(g_MenuNPCEbay, "| NPC Ebay |\nQuel habille d‚sirez-vous acheter ?");
                decl String:buffer[16];
                decl String:InfoObjet[60];
                new i = 0;
                while (i < 84) {
                    if (objetIdAssoc[i][0][0] == 31) {
                        Format(buffer, 16, "%d,%d", i, entity);
                        Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i][0][0] * 20 / 100 + objetPrix[i][0][0]);
                        AddMenuItem(g_MenuNPCEbay, buffer, InfoObjet, 0);
                        i++;
                    }
                    i++;
                }
                DisplayMenu(g_MenuNPCEbay, client, 300);
            } else {
                PrintToChat(client, "%s Vous ne pouvez pas changer d'habille !", "[Rp Magnetik : ->]");
            }
        }
        if (entity == 1325) {
            new Handle:g_MenuNPCmicroshop = CreateMenu(MenuHandler:75, MenuAction:28);
            SetMenuTitle(g_MenuNPCmicroshop, "| NPC Microshop |\nQuel drogue d‚sirez-vous acheter ?");
            decl String:buffer[16];
            decl String:InfoObjet[60];
            new i = 0;
            while (i < 84) {
                if (objetIdAssoc[i][0][0] == 29) {
                    Format(buffer, 16, "%d,%d", i, entity);
                    Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i][0][0] * 20 / 100 + objetPrix[i][0][0]);
                    AddMenuItem(g_MenuNPCmicroshop, buffer, InfoObjet, 0);
                    i++;
                }
                i++;
            }
            DisplayMenu(g_MenuNPCmicroshop, client, 300);
        }
        if (entity == 1317) {
            new Handle:g_MenuNpcIkea = CreateMenu(MenuHandler:87, MenuAction:28);
            SetMenuTitle(g_MenuNpcIkea, "| Acheter des objets d'Ikea |");
            AddMenuItem(g_MenuNpcIkea, "1", "Un distributeur 240$", 0);
            AddMenuItem(g_MenuNpcIkea, "2", "Un canap‚ 60$", 0);
            AddMenuItem(g_MenuNpcIkea, "3", "Une bibliothŠque 120$", 0);
            AddMenuItem(g_MenuNpcIkea, "4", "Une machine … laver 42$", 0);
            AddMenuItem(g_MenuNpcIkea, "5", "Une gazini‚re 216$", 0);
            AddMenuItem(g_MenuNpcIkea, "6", "Une table … manger 180$", 0);
            AddMenuItem(g_MenuNpcIkea, "7", "Une chaise 30$", 0);
            AddMenuItem(g_MenuNpcIkea, "8", "Un pot de fleur 18$", 0);
            AddMenuItem(g_MenuNpcIkea, "9", "Une table en bois 150$", 0);
            AddMenuItem(g_MenuNpcIkea, "10", "Un grand placard  240$", 0);
            DisplayMenu(g_MenuNpcIkea, client, 300);
        }
        if (entity == 1319) {
            new Handle:g_MenuNPCBarman = CreateMenu(MenuHandler:75, MenuAction:28);
            SetMenuTitle(g_MenuNPCBarman, "| NPC Barman |\nQuel boisson d‚sirez-vous acheter ?");
            decl String:buffer[16];
            decl String:InfoObjet[60];
            new i = 0;
            while (i < 84) {
                if (objetIdAssoc[i][0][0] == 27) {
                    Format(buffer, 16, "%d,%d", i, entity);
                    Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i][0][0] * 20 / 100 + objetPrix[i][0][0]);
                    AddMenuItem(g_MenuNPCBarman, buffer, InfoObjet, 0);
                    i++;
                }
                i++;
            }
            DisplayMenu(g_MenuNPCBarman, client, 300);
        }
        if (entity == 1315) {
            new Handle:g_MenuNPCpizza = CreateMenu(MenuHandler:75, MenuAction:28);
            SetMenuTitle(g_MenuNPCpizza, "| NPC Pizza yollo |\nQuel pizza d‚sirez-vous acheter ?");
            decl String:buffer[16];
            decl String:InfoObjet[60];
            new i = 0;
            while (i < 84) {
                if (objetIdAssoc[i][0][0] == 9) {
                    Format(buffer, 16, "%d,%d", i, entity);
                    Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i][0][0] * 20 / 100 + objetPrix[i][0][0]);
                    AddMenuItem(g_MenuNPCpizza, buffer, InfoObjet, 0);
                    i++;
                }
                i++;
            }
            DisplayMenu(g_MenuNPCpizza, client, 300);
        }
        if (entity == 1327) {
            new Handle:g_MenuNPCMedic = CreateMenu(MenuHandler:75, MenuAction:28);
            SetMenuTitle(g_MenuNPCMedic, "| NPC Hopital |\nQuel m‚dicament d‚sirez-vous acheter ?");
            decl String:buffer[16];
            decl String:InfoObjet[60];
            new i = 0;
            while (i < 84) {
                if (objetIdAssoc[i][0][0] == 6) {
                    Format(buffer, 16, "%d,%d", i, entity);
                    Format(InfoObjet, 60, "%s %d:%s %d $", objetNom[i][0][0], objetEffet[i], objetFonction[i][0][0], objetPrix[i][0][0] * 20 / 100 + objetPrix[i][0][0]);
                    AddMenuItem(g_MenuNPCMedic, buffer, InfoObjet, 0);
                    i++;
                }
                i++;
            }
            DisplayMenu(g_MenuNPCMedic, client, 300);
        }
    }
    return 0;
}

public BlockMenuNPCMonit(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[12][8];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 6);
    new num = StringToInt(split[0][split], 10);
    new entity = StringToInt(split[4], 10);
    if (ProcheJoueurPorte(entity, client)) {
        if (num == 1) {
            new cash = clientCash[client][0][0];
            if (0 < cash) {
                if (clientPermiSec[client][0][0] == true) {
                    PrintToChat(client, "%s Vous avez d‚j… le permi de port d'arme secondaire !", "[Rp Magnetik : ->]");
                } else {
                    new var1 = clientCash[client];
                    var1 = var1[0][0] + -3000;
                    clientPermiSec[client] = 1;
                    DonneargentAuProprietaireDuMag(entity, 3000);
                    PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes secondaire !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
            }
        } else {
            if (num == 2) {
                new cash = clientCash[client][0][0];
                if (0 < cash) {
                    if (clientPermiPri[client][0][0] == true) {
                        PrintToChat(client, "%s Vous avez d‚j… le permi de port d'arme primaire !", "[Rp Magnetik : ->]");
                    } else {
                        new var2 = clientCash[client];
                        var2 = var2[0][0] + -4200;
                        clientPermiPri[client] = 1;
                        DonneargentAuProprietaireDuMag(entity, 4200);
                        PrintToChat(client, "%s F‚licitation vous avez la permission d'avoir des armes primaire !", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
                }
            }
            if (num == 3) {
                new Handle:g_MenuNPCPrecision = CreateMenu(MenuHandler:89, MenuAction:28);
                SetMenuTitle(g_MenuNPCPrecision, "| Pr‚cision de tir |");
                AddMenuItem(g_MenuNPCPrecision, "1", "1 Pr‚cision 36$", 0);
                AddMenuItem(g_MenuNPCPrecision, "2", "2 Pr‚cision 72$", 0);
                AddMenuItem(g_MenuNPCPrecision, "5", "5 Pr‚cision 180$", 0);
                AddMenuItem(g_MenuNPCPrecision, "10", "10 Pr‚cision 360$", 0);
                AddMenuItem(g_MenuNPCPrecision, "20", "20 Pr‚cision 720$", 0);
                AddMenuItem(g_MenuNPCPrecision, "50", "50 Pr‚cision 1800$", 0);
                AddMenuItem(g_MenuNPCPrecision, "70", "70 Pr‚cision 2520$", 0);
                AddMenuItem(g_MenuNPCPrecision, "100", "100 Pr‚cision 3600$", 0);
                DisplayMenu(g_MenuNPCPrecision, client, 300);
            }
            new compte = verifieAsseArgent(client, objetPrix[num][0][0] * 20 / 100 + objetPrix[num][0][0]);
            if (compte) {
                new place = TrouverPlaceDansSac(client, num);
                if (0 < place) {
                    if (compte == 1) {
                        DonneargentAuProprietaireDuMag(entity, objetPrix[num][0][0] * 20 / 100 + objetPrix[num][0][0]);
                        new var3 = clientCash[client];
                        var3 = var3[0][0] - objetPrix[num][0][0] * 20 / 100 + objetPrix[num][0][0];
                        PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre portefeuille !", "[Rp Magnetik : ->]", objetPrix[num][0][0] * 20 / 100 + objetPrix[num][0][0]);
                    } else {
                        if (compte == 2) {
                            DonneargentAuProprietaireDuMag(entity, objetPrix[num][0][0] * 20 / 100 + objetPrix[num][0][0]);
                            new var4 = clientBank[client];
                            var4 = var4[0][0] - objetPrix[num][0][0] * 20 / 100 + objetPrix[num][0][0];
                            PrintToChat(client, "%s %d$ on ‚tait retir‚ de votre compte bancaire !", "[Rp Magnetik : ->]", objetPrix[num][0][0] * 20 / 100 + objetPrix[num][0][0]);
                        }
                        return 0;
                    }
                    MettreObjetDansSac(client, place, num);
                    OuvirMenuSac(client);
                } else {
                    PrintToChat(client, "%s Vous avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous n'avez plus d'argent ! ", "[Rp Magnetik : ->]");
            }
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockNPCLevelPrecision(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[12][8];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 6);
    new num = StringToInt(split[0][split], 10);
    if (ProcheJoueurPorte(1309, client)) {
        new compte = verifieAsseArgent(client, num * 36);
        if (compte) {
            new sonLevel = clientPrecision[client][0][0];
            if (num + sonLevel < 101) {
                if (compte == 1) {
                    new var1 = clientCash[client];
                    var1 = var1[0][0] - num * 36;
                    DonneargentAuProprietaireDuMag(1309, num * 36);
                    new var2 = clientPrecision[client];
                    var2 = var2[0][0] + num;
                    PrintToChat(client, "%s Transaction valid‚ ! %d$ on ‚tait retirer de ton portefeuille", "[Rp Magnetik : ->]", num * 36);
                    voirMonLevelKnife(client);
                } else {
                    if (compte == 2) {
                        new var3 = clientBank[client];
                        var3 = var3[0][0] - num * 36;
                        DonneargentAuProprietaireDuMag(1309, num * 36);
                        new var4 = clientPrecision[client];
                        var4 = var4[0][0] + num;
                        PrintToChat(client, "%s Transaction valid‚ ! %d$ on ‚tait retirer de ton compte bancaire", "[Rp Magnetik : ->]", num * 36);
                        voirMonLevelKnife(client);
                    }
                    return 0;
                }
            } else {
                PrintToChat(client, "%s Vous ne pouvez pas d‚passer le level de pr‚cision de 100/100 !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuNPCObjet(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[12][16];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 16);
    new idObjet = StringToInt(split[0][split], 10);
    new entity = StringToInt(split[4], 10);
    if (ProcheJoueurPorte(entity, client)) {
        new compte = verifieAsseArgent(client, objetPrix[idObjet][0][0] * 20 / 100 + objetPrix[idObjet][0][0]);
        if (compte) {
            new place = TrouverPlaceDansSac(client, idObjet);
            if (0 < place) {
                if (compte == 1) {
                    DonneargentAuProprietaireDuMag(entity, objetPrix[idObjet][0][0] * 20 / 100 + objetPrix[idObjet][0][0]);
                    new var1 = clientCash[client];
                    var1 = var1[0][0] - objetPrix[idObjet][0][0] * 20 / 100 + objetPrix[idObjet][0][0];
                    MettreObjetDansSac(client, place, idObjet);
                    PrintToChat(client, "%s Objet ajouter dans votre sac !", "[Rp Magnetik : ->]");
                } else {
                    if (compte == 2) {
                        DonneargentAuProprietaireDuMag(entity, objetPrix[idObjet][0][0] * 20 / 100 + objetPrix[idObjet][0][0]);
                        new var2 = clientBank[client];
                        var2 = var2[0][0] - objetPrix[idObjet][0][0] * 20 / 100 + objetPrix[idObjet][0][0];
                        MettreObjetDansSac(client, place, idObjet);
                        PrintToChat(client, "%s Objet ajouter dans votre sac !", "[Rp Magnetik : ->]");
                    }
                    return 0;
                }
            } else {
                PrintToChat(client, "%s Vous n'avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockNPCAcheterIkea(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    new idObjet = StringToInt(parametre, 10) + -1;
    if (ProcheJoueurPorte(1317, client)) {
        new compte = verifieAsseArgent(client, listPropPrix[idObjet][0][0] * 20 / 100 + listPropPrix[idObjet][0][0]);
        if (compte) {
            if (compte == 1) {
                DonneargentAuProprietaireDuMag(1317, listPropPrix[idObjet][0][0] * 20 / 100 + listPropPrix[idObjet][0][0]);
                new var1 = clientCash[client];
                var1 = var1[0][0] - listPropPrix[idObjet][0][0] * 20 / 100 + listPropPrix[idObjet][0][0];
                PrintToChat(client, "%s Transaction valid‚ ! %d$ on ‚tait retirer de ton portefeuille", "[Rp Magnetik : ->]", listPropPrix[idObjet][0][0] * 20 / 100 + listPropPrix[idObjet][0][0]);
                decl Float:destinationProp[3];
                destinationProp[0] = -999158136;
                destinationProp[4] = -987655481;
                destinationProp[8] = -1010926592;
                spawnPropIkea(idObjet, destinationProp);
            } else {
                if (compte == 2) {
                    DonneargentAuProprietaireDuMag(1317, listPropPrix[idObjet][0][0] * 20 / 100 + listPropPrix[idObjet][0][0]);
                    new var2 = clientBank[client];
                    var2 = var2[0][0] - listPropPrix[idObjet][0][0] * 20 / 100 + listPropPrix[idObjet][0][0];
                    PrintToChat(client, "%s Transaction valid‚ ! %d$ on ‚tait retirer de ton compte bancaire", "[Rp Magnetik : ->]", listPropPrix[idObjet][0][0] * 20 / 100 + listPropPrix[idObjet][0][0]);
                    decl Float:destinationProp[3];
                    destinationProp[0] = -999158136;
                    destinationProp[4] = -987655481;
                    destinationProp[8] = -1010926592;
                    spawnPropIkea(idObjet, destinationProp);
                }
                return 0;
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

DonneargentAuProprietaireDuMag(entity, sommeDargent)
{
    if (entity == 1312) {
        if (!PasDeProProprietaire(listPorteArmurie[0][0])) {
            decl String:steamid[32];
            strcopy(steamid, 32, porteProprio1[listPorteArmurie[0][0]][0][0]);
            AjouterArgentCapitalNPC(steamid, sommeDargent);
        }
    } else {
        if (entity == 1309) {
            if (!PasDeProProprietaire(listPorteMoniteurTir[0][0])) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[listPorteMoniteurTir[0][0]][0][0]);
                AjouterArgentCapitalNPC(steamid, sommeDargent);
            }
        }
        if (entity == 1324) {
            if (!PasDeProProprietaire(32)) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[128][0]);
                AjouterArgentCapitalNPC(steamid, sommeDargent);
            }
        }
        if (entity == 1325) {
            if (!PasDeProProprietaire(33)) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[132][0]);
                AjouterArgentCapitalNPC(steamid, sommeDargent);
            }
        }
        if (entity == 1317) {
            if (!PasDeProProprietaire(listPorteIkea[0][0])) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[listPorteIkea[0][0]][0][0]);
                AjouterArgentCapitalNPC(steamid, sommeDargent);
            }
        }
        if (entity == 1319) {
            if (!PasDeProProprietaire(listPorteBar[0][0])) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[listPorteBar[0][0]][0][0]);
                AjouterArgentCapitalNPC(steamid, sommeDargent);
            }
        }
        if (entity == 1315) {
            if (!PasDeProProprietaire(listPortePizzeria[0][0])) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[listPortePizzeria[0][0]][0][0]);
                AjouterArgentCapitalNPC(steamid, sommeDargent);
            }
        }
        if (entity == 1327) {
            if (!PasDeProProprietaire(97)) {
                decl String:steamid[32];
                strcopy(steamid, 32, porteProprio1[388][0]);
                AjouterArgentCapitalNPC(steamid, sommeDargent);
            }
        }
    }
    return 0;
}

donneUnKitDeCrochetage(client, entity)
{
    new SonIdMetier = clientIdMetier[client][0][0];
    if (inList(SonIdMetier, listMetierMafieu, 6)) {
        if (ProcheJoueurPorte(entity, client)) {
            new var1;
            if (SonIdMetier == 35) {
                donnerUnKIT(client);
            }
            new var3;
            if (SonIdMetier == 37) {
                donnerUnKIT(client);
            }
            new var5;
            if (SonIdMetier == 39) {
                donnerUnKIT(client);
            }
            PrintToChat(client, "%s Vous ne pouvez pas avoir un kit de crochetage d'une autre mafia", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

donnerUnKIT(client)
{
    new place = TrouverPlaceDansSac(client, 64);
    if (place) {
        new nbrKit = TrouverLeNombredeKit(client);
        if (nbrKit < 15) {
            MettreObjetDansSac(client, place, 64);
            PrintToChat(client, "%s Kit de crochetage rajout‚ dans votre sac !", "[Rp Magnetik : ->]");
            if (!IsSoundPrecached("items/itempickup.wav")) {
                PrecacheSound("items/itempickup.wav", true);
            }
            decl Float:eyeposition[3];
            GetClientEyePosition(client, eyeposition);
            EmitSoundToClient(client, "items/itempickup.wav", client, 0, 75, 0, 1, 100, -1, eyeposition, NULL_VECTOR, true, 0);
        } else {
            PrintToChat(client, "%s Vous avez d‚j… %d kit de crochetage dans votre sac !", "[Rp Magnetik : ->]", 15);
        }
    } else {
        PrintToChat(client, "%s Vous avez plus de place dans votre sac !", "[Rp Magnetik : ->]");
    }
    return 0;
}

TrouverLeNombredeKit(client)
{
    new valeur = 0;
    decl tab[10];
    tab[0] = clientItem1[client][0][0];
    tab[4] = clientItem2[client][0][0];
    tab[8] = clientItem3[client][0][0];
    tab[12] = clientItem4[client][0][0];
    tab[16] = clientItem5[client][0][0];
    tab[20] = clientItem6[client][0][0];
    tab[24] = clientItem7[client][0][0];
    tab[28] = clientItem8[client][0][0];
    tab[32] = clientItem9[client][0][0];
    tab[36] = clientItem10[client][0][0];
    decl tabNbr[10];
    tabNbr[0] = clientNbr1[client][0][0];
    tabNbr[4] = clientNbr2[client][0][0];
    tabNbr[8] = clientNbr3[client][0][0];
    tabNbr[12] = clientNbr4[client][0][0];
    tabNbr[16] = clientNbr5[client][0][0];
    tabNbr[20] = clientNbr6[client][0][0];
    tabNbr[24] = clientNbr7[client][0][0];
    tabNbr[28] = clientNbr8[client][0][0];
    tabNbr[32] = clientNbr9[client][0][0];
    tabNbr[36] = clientNbr10[client][0][0];
    new j = 0;
    while (j < 10) {
        if (tab[j] == 64) {
            valeur = tabNbr[j];
            j++;
        }
        j++;
    }
    return valeur;
}

CreateMenuNpcPrincipal()
{
    panelNpcPrincipale = CreatePanel(Handle:0);
    SetPanelTitle(panelNpcPrincipale, "| NPC Principal |", false);
    SetPanelKeys(panelNpcPrincipale, 1023);
    DrawPanelText(panelNpcPrincipale, " ");
    DrawPanelText(panelNpcPrincipale, "->1. Qu'est ce que le RolePlay ?");
    DrawPanelText(panelNpcPrincipale, "->2. Les commandes utiles ?");
    DrawPanelText(panelNpcPrincipale, "->3. Informations commerciales ?");
    DrawPanelText(panelNpcPrincipale, "->4. Informations m‚tiers ?");
    DrawPanelText(panelNpcPrincipale, "->5. Informations logements ?");
    DrawPanelText(panelNpcPrincipale, "->6. Inscription Event Guerre de Gangs");
    DrawPanelText(panelNpcPrincipale, "->9. Au revoir !");
    panelLeRoleplay = CreatePanel(Handle:0);
    SetPanelTitle(panelLeRoleplay, "| NPC Principal |\nQu'est ce que le RolePlay ?", false);
    SetPanelKeys(panelLeRoleplay, 1023);
    DrawPanelText(panelLeRoleplay, " ");
    DrawPanelText(panelLeRoleplay, "Le roleplay est un mode de jeu o—");
    DrawPanelText(panelLeRoleplay, "l'on doit incarner un r“le. Exemple");
    DrawPanelText(panelLeRoleplay, "ˆtre : Dealer, Agent FBI, Pizza yollo etc...");
    DrawPanelText(panelLeRoleplay, "Pour avoir un m‚tier il faut soit ˆtre");
    DrawPanelText(panelLeRoleplay, "recrut‚ par un chef de m‚tier ou soit");
    DrawPanelText(panelLeRoleplay, "postuler sur le forum (!site dans tchat)");
    DrawPanelText(panelLeRoleplay, "->9. Menu Principal");
    panelCommande = CreatePanel(Handle:0);
    SetPanelTitle(panelCommande, "| NPC Principal |\nLes commandes utiles ?", false);
    SetPanelKeys(panelCommande, 1023);
    DrawPanelText(panelCommande, " ");
    DrawPanelText(panelCommande, "Touche utiliser pour prendre un objet");
    DrawPanelText(panelCommande, "!sac ou !bag aller dans votre sac");
    DrawPanelText(panelCommande, "!level voir le level du knife et de pr‚cision");
    DrawPanelText(panelCommande, "!cle v‚rrouiller ou d‚verouiller une porte");
    DrawPanelText(panelCommande, "!give <nbrd'argent> donner de l'argent");
    DrawPanelText(panelCommande, "!vendre !sell vendre un objet");
    DrawPanelText(panelCommande, "->8. Page suivante");
    DrawPanelText(panelCommande, "->9. Menu Principal");
    panelCommande1 = CreatePanel(Handle:0);
    SetPanelTitle(panelCommande1, "| NPC Principal |\nLes commandes utiles ?", false);
    SetPanelKeys(panelCommande1, 1023);
    DrawPanelText(panelCommande1, " ");
    DrawPanelText(panelCommande1, "!acheter !buy acheter un objet");
    DrawPanelText(panelCommande1, "!recrute engager une personne (4 maxi)");
    DrawPanelText(panelCommande1, "!donnecle !givekey donner un double des cl‚s(4 maxi)");
    DrawPanelText(panelCommande1, "!retircle !removekey retirer les cl‚s … qlq");
    DrawPanelText(panelCommande1, "!flic !police menu pour la s‚curit‚");
    DrawPanelText(panelCommande1, "!vol pour faire les poche d'une personne(Mafia)");
    DrawPanelText(panelCommande1, "!enquete enqueter sur une personne(D‚tective)");
    DrawPanelText(panelCommande1, "!porte Information sur une porte");
    DrawPanelText(panelCommande1, "!out faire sortir quelqu'un de votre planque");
    DrawPanelText(panelCommande1, "->9. Menu Principal");
    panelInfoMetier = CreatePanel(Handle:0);
    SetPanelTitle(panelInfoMetier, "| NPC Principal |\nInformations m‚tiers ?", false);
    SetPanelKeys(panelInfoMetier, 1023);
    DrawPanelText(panelInfoMetier, " ");
    DrawPanelText(panelInfoMetier, "->1. Liste des m‚tiers existants ?");
    DrawPanelText(panelInfoMetier, "->2. D‚missionner !");
    DrawPanelText(panelInfoMetier, "->3. Licencier une personnes");
    DrawPanelText(panelInfoMetier, "->4. Vos recettes");
    DrawPanelText(panelInfoMetier, "->5. D‚finir le salaire");
    DrawPanelText(panelInfoMetier, "->9. Menu Principal");
    panelMetierExistant = CreatePanel(Handle:0);
    SetPanelTitle(panelMetierExistant, "| NPC Principal |\nM‚tiers existants ?", false);
    SetPanelKeys(panelMetierExistant, 1023);
    DrawPanelText(panelMetierExistant, " ");
    new i = 0;
    while (i < 40) {
        if (metierIdAssoc[i][0][0] == -1) {
            DrawPanelText(panelMetierExistant, metierNom[i][0][0]);
            i++;
        }
        i++;
    }
    DrawPanelText(panelMetierExistant, "->9. Menu Principal");
    panelInfoMagasin = CreatePanel(Handle:0);
    SetPanelTitle(panelInfoMagasin, "| NPC Principal |\nInformations commerciales ?", false);
    SetPanelKeys(panelInfoMagasin, 1023);
    DrawPanelText(panelInfoMagasin, " ");
    DrawPanelText(panelInfoMagasin, "->1. Liste des commerces existants ?");
    DrawPanelText(panelInfoMagasin, "->2. Louer un commerce");
    DrawPanelText(panelInfoMagasin, "->3. Stoper une location");
    DrawPanelText(panelInfoMagasin, "->9. Menu Principal");
    panelInfoAppart = CreatePanel(Handle:0);
    SetPanelTitle(panelInfoAppart, "| NPC Principal |\nInformations Appartements ?", false);
    SetPanelKeys(panelInfoAppart, 1023);
    DrawPanelText(panelInfoAppart, " ");
    DrawPanelText(panelInfoAppart, "->1. Liste des apparts existants ?");
    DrawPanelText(panelInfoAppart, "->2. Location d'un appartement");
    DrawPanelText(panelInfoAppart, "->3. Stoper une location");
    DrawPanelText(panelInfoAppart, "->9. Menu Principal");
    return 0;
}

affichageMenuPrincipale(client, entity)
{
    if (ProcheJoueurPorte(entity, client)) {
        OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        PrintToChat(client, "%s Bonjour !  *NPC Principal", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelNpcPrincipale(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 1) {
            OpenMenu(client, panelLeRoleplay, MenuHandler:165);
            PrintToChat(client, "%s Des informations sur le Roleplay ? en voici... *NPC Principal", "[Rp Magnetik : ->]");
        } else {
            if (choice == 2) {
                OpenMenu(client, panelCommande, MenuHandler:153);
                PrintToChat(client, "%s Quelque commande int‚ressante... *NPC Principal", "[Rp Magnetik : ->]");
            }
            if (choice == 3) {
                OpenMenu(client, panelInfoMagasin, MenuHandler:161);
                PrintToChat(client, "%s Business to business... *NPC Principal", "[Rp Magnetik : ->]");
            }
            if (choice == 4) {
                OpenMenu(client, panelInfoMetier, MenuHandler:163);
                PrintToChat(client, "%s Pole emploi … votre service... *NPC Principal", "[Rp Magnetik : ->]");
            }
            if (choice == 5) {
                OpenMenu(client, panelInfoAppart, MenuHandler:159);
                PrintToChat(client, "%s Besoin d'une planque... *NPC Principal", "[Rp Magnetik : ->]");
            }
            if (choice == 6) {
                InscriptionALevent(client);
                PrintToChat(client, "%s Bonne chance pour l'event ! *NPC Principal", "[Rp Magnetik : ->]");
            }
            if (choice == 9) {
                PrintToChat(client, "%s Au revoir ! *NPC Principal", "[Rp Magnetik : ->]");
            }
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelInfoAppart(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 1) {
            PrintToChat(client, "%s Voici les appartements existants ! *NPC Principal", "[Rp Magnetik : ->]");
            new Handle:panelAppartExistant = CreateMenu(MenuHandler:151, MenuAction:28);
            SetMenuTitle(panelAppartExistant, "| NPC Principal |\nAppartement existant ?");
            decl String:text[60];
            new i = 0;
            while (i < 18) {
                Format(text, 60, "%s |Louer: %d min", porteNom[listAppartPrincipal[i][0][0]][0][0], porteLocation[listAppartPrincipal[i][0][0]][0][0] / 60);
                AddMenuItem(panelAppartExistant, "9", text, 0);
                i++;
            }
            AddMenuItem(panelAppartExistant, "9", "Menu Principal", 0);
            DisplayMenu(panelAppartExistant, client, 300);
        } else {
            if (choice == 2) {
                if (!DetientUnAppartement(client)) {
                    PrintToChat(client, "%s Voici les appartements que vous pouvez louer ! *NPC Principal", "[Rp Magnetik : ->]");
                    new Handle:g_MenuAcheterAppart = CreateMenu(MenuHandler:43, MenuAction:28);
                    SetMenuTitle(g_MenuAcheterAppart, "| Louer un appartement |\nQuel Appart d‚sirez-vous louer ?");
                    decl String:parametre[8];
                    decl String:buffer[64];
                    new appart = 0;
                    new i = 0;
                    while (i < 18) {
                        appart = listAppartPrincipal[i][0][0];
                        if (StrEqual(porteProprio1[appart][0][0], "Aucun", true)) {
                            Format(parametre, 5, "%d", appart);
                            Format(buffer, 64, "%s prix: %d$ / Jour", porteNom[appart][0][0], portePrix[appart]);
                            AddMenuItem(g_MenuAcheterAppart, parametre, buffer, 0);
                            i++;
                        }
                        i++;
                    }
                    AddMenuItem(g_MenuAcheterAppart, "-1", "Menu Principal", 0);
                    DisplayMenu(g_MenuAcheterAppart, client, 300);
                } else {
                    PrintToChat(client, "%s Vous d‚tenez d‚j… un appartement donc vous ne pouvez plus en louer *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (choice == 3) {
                PrintToChat(client, "%s Vous ne serez plus propri‚taire de l'appartement *NPC Principal", "[Rp Magnetik : ->]");
                if (DetientUnAppartement(client)) {
                    new numero = NumeroDeAppartDetenu(client);
                    if (numero != -1) {
                        new Handle:g_MenuStopLouerAppart = CreateMenu(MenuHandler:81, MenuAction:28);
                        SetMenuTitle(g_MenuStopLouerAppart, "| Voulez-vous stoper la location de : %s ? |\n| Vous ne serez plus propri‚taire ! |", porteNom[numero][0][0]);
                        decl String:parametre[8];
                        Format(parametre, 5, "%d", numero);
                        AddMenuItem(g_MenuStopLouerAppart, parametre, "Accepter", 0);
                        Format(parametre, 5, "-1");
                        AddMenuItem(g_MenuStopLouerAppart, parametre, "Refuser", 0);
                        DisplayMenu(g_MenuStopLouerAppart, client, 300);
                    } else {
                        PrintToChat(client, "%s Vous n'avez plus de logement … stoper la location ! *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Vous n'avez pas de logement ! *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (choice == 9) {
                OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
            }
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuStoperLouerAppart(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 5, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == -1) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
            PrintToChat(client, "%s Vous avez bien fait de refuser ! *NPC Principal", "[Rp Magnetik : ->]");
        }
        FindeLocationAppartment(num);
        PrintToChat(client, "%s Vous n'ˆtes plus propri‚taire de : %s *NPC Principal", "[Rp Magnetik : ->]", porteNom[num][0][0]);
    }
    return 0;
}

public BlockMenuRevendreUNAppart(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 5, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == -1) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuAcheterAppart(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 5, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == -1) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        } else {
            new Handle:g_MenuTempsLocAppart = CreateMenu(MenuHandler:109, MenuAction:28);
            decl String:titre[128];
            Format(titre, 128, "| Combien de temps voulez-vous louer ? |\n| %s |", porteNom[num][0][0]);
            SetMenuTitle(g_MenuTempsLocAppart, titre);
            decl String:buffer[16];
            decl String:paramat[64];
            Format(buffer, 16, "1,%d", num);
            Format(paramat, 64, "1 jour r‚el soit %d $", portePrix[num]);
            AddMenuItem(g_MenuTempsLocAppart, buffer, paramat, 0);
            Format(buffer, 16, "2,%d", num);
            Format(paramat, 64, "2 jours r‚el soit %d $", portePrix[num][0][0] * 2);
            AddMenuItem(g_MenuTempsLocAppart, buffer, paramat, 0);
            Format(buffer, 16, "3,%d", num);
            Format(paramat, 64, "3 jours r‚el soit %d $", portePrix[num][0][0] * 3);
            AddMenuItem(g_MenuTempsLocAppart, buffer, paramat, 0);
            Format(buffer, 16, "4,%d", num);
            Format(paramat, 64, "4 jours r‚el soit %d $", portePrix[num][0][0] * 4);
            AddMenuItem(g_MenuTempsLocAppart, buffer, paramat, 0);
            Format(buffer, 16, "5,%d", num);
            Format(paramat, 64, "5 jours r‚el soit %d $", portePrix[num][0][0] * 5);
            AddMenuItem(g_MenuTempsLocAppart, buffer, paramat, 0);
            Format(buffer, 16, "6,%d", num);
            Format(paramat, 64, "6 jours r‚el soit %d $", portePrix[num][0][0] * 6);
            AddMenuItem(g_MenuTempsLocAppart, buffer, paramat, 0);
            Format(buffer, 16, "7,%d", num);
            Format(paramat, 64, "7 jours r‚el soit %d $", portePrix[num][0][0] * 7);
            AddMenuItem(g_MenuTempsLocAppart, buffer, paramat, 0);
            DisplayMenu(g_MenuTempsLocAppart, client, 300);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockTempsDeLocationAppart(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[8][16];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 2, 16);
    new nbrJour = StringToInt(split[0][split], 10);
    new index = StringToInt(split[4], 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (nbrJour * portePrix[index][0][0] <= clientCash[client][0][0]) {
            LouerUnAppart(client, index, nbrJour);
        } else {
            PrintToChat(client, "%s Je ne peux pas vous louer ce commerce, car vous n'avez pas assez d'argent *NPC Principal", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelInfoMagasin(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 1) {
            PrintToChat(client, "%s Voici les commerces existants ! *NPC Principal", "[Rp Magnetik : ->]");
            new Handle:panelMagasinExistant = CreatePanel(Handle:0);
            SetPanelTitle(panelMagasinExistant, "| NPC Principal |\nCommerce existant ?", false);
            SetPanelKeys(panelMagasinExistant, 1023);
            decl String:text[60];
            DrawPanelText(panelMagasinExistant, " ");
            new i = 0;
            while (i < 13) {
                Format(text, 60, "%s |Louer: %d min", porteNom[listMagasin[i][0][0]][0][0], porteLocation[listMagasin[i][0][0]][0][0] / 60);
                DrawPanelText(panelMagasinExistant, text);
                i++;
            }
            DrawPanelText(panelMagasinExistant, "->9. Menu Principal");
            OpenMenu(client, panelMagasinExistant, MenuHandler:167);
        } else {
            if (choice == 2) {
                PrintToChat(client, "%s Pour louer un commerce, il faut avoir le m‚tier correspondant et bien s–r avoir de l'argent :) *NPC Principal", "[Rp Magnetik : ->]");
                if (!DetientUnMagasin(client)) {
                    new Handle:g_MenuAcheterMagasin = CreateMenu(MenuHandler:45, MenuAction:28);
                    SetMenuTitle(g_MenuAcheterMagasin, "| Quel commerce d‚sirez-vous louer ? |");
                    decl String:parametre[8];
                    decl String:buffer[64];
                    new magasin = 0;
                    new i = 0;
                    while (i < 13) {
                        magasin = listMagasin[i][0][0];
                        if (StrEqual(porteProprio1[magasin][0][0], "Aucun", true)) {
                            Format(parametre, 5, "%d", magasin);
                            Format(buffer, 64, "%s prix: %d$/Jour", porteNom[magasin][0][0], portePrix[magasin]);
                            AddMenuItem(g_MenuAcheterMagasin, parametre, buffer, 0);
                            i++;
                        }
                        i++;
                    }
                    AddMenuItem(g_MenuAcheterMagasin, "-1", "Menu Principal", 0);
                    DisplayMenu(g_MenuAcheterMagasin, client, 300);
                } else {
                    PrintToChat(client, "%s Vous d‚tenez d‚j… un commerce donc vous pouvez plus en louer *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (choice == 3) {
                PrintToChat(client, "%s Vous ne serez plus propri‚taire du commerce *NPC Principal", "[Rp Magnetik : ->]");
                if (DetientUnMagasin(client)) {
                    new numero = NumeroDuMagasinDetenu(client);
                    if (numero != -1) {
                        new Handle:g_MenuVendreMagasin = CreateMenu(MenuHandler:83, MenuAction:28);
                        SetMenuTitle(g_MenuVendreMagasin, "| Voulez-vous stoper la location de : %s ? |\n | Vous ne serez plus propri‚taire ! |", porteNom[numero][0][0]);
                        decl String:parametre[8];
                        Format(parametre, 5, "%d", numero);
                        AddMenuItem(g_MenuVendreMagasin, parametre, "Accepter", 0);
                        Format(parametre, 5, "-1");
                        AddMenuItem(g_MenuVendreMagasin, parametre, "Refuser", 0);
                        DisplayMenu(g_MenuVendreMagasin, client, 300);
                    } else {
                        PrintToChat(client, "%s Vous n'avez plus de commerce … stoper la location ! *NPC Principal", "[Rp Magnetik : ->]");
                    }
                } else {
                    PrintToChat(client, "%s Vous n'avez pas de commerce ! *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (choice == 9) {
                OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
            }
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuVendreMagasin(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 5, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == -1) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
            PrintToChat(client, "%s Vous avez bien fait de refuser ! *NPC Principal", "[Rp Magnetik : ->]");
        }
        FinDeLocationUnMagasin(num);
        PrintToChat(client, "%s Vous n'ˆtes plus propri‚taire de : %s *NPC Principal", "[Rp Magnetik : ->]", porteNom[num][0][0]);
    }
    return 0;
}

public BlockMenuAcheterMagasin(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 5, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == -1) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        } else {
            new Handle:g_MenuTempsLocCommer = CreateMenu(MenuHandler:111, MenuAction:28);
            decl String:titre[128];
            Format(titre, 128, "| Combien de temps voulez-vous louer ? |\n| %s |", porteNom[num][0][0]);
            SetMenuTitle(g_MenuTempsLocCommer, titre);
            decl String:buffer[16];
            decl String:paramat[64];
            Format(buffer, 16, "1,%d", num);
            Format(paramat, 64, "1 jour r‚el soit %d $", portePrix[num]);
            AddMenuItem(g_MenuTempsLocCommer, buffer, paramat, 0);
            Format(buffer, 16, "2,%d", num);
            Format(paramat, 64, "2 jours r‚el soit %d $", portePrix[num][0][0] * 2);
            AddMenuItem(g_MenuTempsLocCommer, buffer, paramat, 0);
            Format(buffer, 16, "3,%d", num);
            Format(paramat, 64, "3 jours r‚el soit %d $", portePrix[num][0][0] * 3);
            AddMenuItem(g_MenuTempsLocCommer, buffer, paramat, 0);
            Format(buffer, 16, "4,%d", num);
            Format(paramat, 64, "4 jours r‚el soit %d $", portePrix[num][0][0] * 4);
            AddMenuItem(g_MenuTempsLocCommer, buffer, paramat, 0);
            Format(buffer, 16, "5,%d", num);
            Format(paramat, 64, "5 jours r‚el soit %d $", portePrix[num][0][0] * 5);
            AddMenuItem(g_MenuTempsLocCommer, buffer, paramat, 0);
            Format(buffer, 16, "6,%d", num);
            Format(paramat, 64, "6 jours r‚el soit %d $", portePrix[num][0][0] * 6);
            AddMenuItem(g_MenuTempsLocCommer, buffer, paramat, 0);
            Format(buffer, 16, "7,%d", num);
            Format(paramat, 64, "7 jours r‚el soit %d $", portePrix[num][0][0] * 7);
            AddMenuItem(g_MenuTempsLocCommer, buffer, paramat, 0);
            DisplayMenu(g_MenuTempsLocCommer, client, 300);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockTempsDeLocationCommerce(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[16];
    decl String:split[8][16];
    GetMenuItem(menu, choice, parametre, 16, 0, "", 0);
    ExplodeString(parametre, ",", split, 2, 16);
    new nbrJour = StringToInt(split[0][split], 10);
    new index = StringToInt(split[4], 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (nbrJour * portePrix[index][0][0] <= clientCash[client][0][0]) {
            LouerUnCommerce(client, index, nbrJour);
        } else {
            PrintToChat(client, "%s Je ne peux pas vous louer ce commerce, car vous n'avez pas assez d'argent *NPC Principal", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelAppartExistant(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 5, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == 9) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelMagasinExistant(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 9) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelInfoMetier(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 1) {
            PrintToChat(client, "%s Voici les m‚tiers existants ! *NPC Principal", "[Rp Magnetik : ->]");
            OpenMenu(client, panelMetierExistant, MenuHandler:169);
        } else {
            if (choice == 2) {
                PrintToChat(client, "%s Attention vous ˆtes sur le point de perdre votre emploi (sans emploi) *NPC Principal", "[Rp Magnetik : ->]");
                new Handle:g_MenuDemissionner = CreateMenu(MenuHandler:53, MenuAction:28);
                SetMenuTitle(g_MenuDemissionner, "| Voulez-vous d‚missionner ? |\nAttention vous serez sans emploie !\nEt vous perdrez votre magasin !");
                AddMenuItem(g_MenuDemissionner, "1", "Accepter", 0);
                AddMenuItem(g_MenuDemissionner, "2", "Refuser", 0);
                DisplayMenu(g_MenuDemissionner, client, 300);
            }
            if (choice == 3) {
                PrintToChat(client, "%s Attention vous ˆtes sur le point de licencier une personne *NPC Principal", "[Rp Magnetik : ->]");
                decl String:bossSteamId[32];
                GetClientAuthString(client, bossSteamId, 32);
                new SonIdMetier = clientIdMetier[client][0][0];
                if (inList(SonIdMetier, listMetierChef, 17)) {
                    decl String:error[256];
                    if (!sltSalarie) {
                        sltSalarie = SQL_PrepareQuery(db, "SELECT st_job1, st_job2, st_job3, st_job4 FROM Bossjob WHERE st_job0 = ?", error, 256);
                        if (sltSalarie) {
                        } else {
                            Log("Roleplay FReZ", "Il y a une erreur dans la preparation de la requete pour NpcPrincipal (error: %s)", error);
                            return 0;
                        }
                    }
                    SQL_BindParamString(sltSalarie, 0, bossSteamId, false);
                    if (!SQL_Execute(sltSalarie)) {
                        Log("Roleplay FReZ", "Impossible de select les salari‚s pour licencier une personne");
                        return 0;
                    }
                    new Handle:g_MenuLicencier = CreateMenu(MenuHandler:71, MenuAction:28);
                    SetMenuTitle(g_MenuLicencier, "| Licencier une personne ? |\nAttention cette personne sera sans emploie !");
                    decl String:steamid[32];
                    decl String:sqlpseudo[256];
                    decl String:pseudo[40];
                    decl String:parametre[64];
                    decl String:buffer[40];
                    if (SQL_FetchRow(sltSalarie)) {
                        new i = 0;
                        while (i < 4) {
                            SQL_FetchString(sltSalarie, i, steamid, 32, 0);
                            if (!StrEqual(steamid, "Aucun", true)) {
                                Format(sqlpseudo, 256, "SELECT pseudo FROM Player WHERE steamid='%s'", steamid);
                                new Handle:req2 = SQL_Query(db, sqlpseudo, -1);
                                if (req2) {
                                    if (SQL_FetchRow(req2)) {
                                        SQL_FetchString(req2, 0, pseudo, 40, 0);
                                        Format(parametre, 64, "%d,%s,%s", i + 1, steamid, pseudo);
                                        Format(buffer, 40, "%s", pseudo);
                                        AddMenuItem(g_MenuLicencier, parametre, buffer, 0);
                                    }
                                }
                                SQL_GetError(db, error, 256);
                                Log("RolePlay Admin", "Impossible de recuperer le pseudo du joueur a licencier (NPC Principal) ->erreur : %s", error);
                                return 0;
                            }
                            i++;
                        }
                    } else {
                        Log("RolePlay Admin", "Impossible de faire un select pour licencier !!");
                    }
                    Format(parametre, 64, "9,aucun");
                    Format(buffer, 40, "Menu principal ");
                    AddMenuItem(g_MenuLicencier, parametre, buffer, 0);
                    DisplayMenu(g_MenuLicencier, client, 300);
                } else {
                    PrintToChat(client, "%s Vous n'ˆtes pas Chef ! *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (choice == 4) {
                new SonIdMetier = clientIdMetier[client][0][0];
                if (inList(SonIdMetier, listMetierChef, 17)) {
                    AfficherRecetteChefEntreprise(client);
                } else {
                    if (inList(SonIdMetier, listMetierSimple, 18)) {
                        AfficherRecetteSalarier(client);
                    }
                    PrintToChat(client, "%s Vous n'avez pas de recette ! *NPC Principal", "[Rp Magnetik : ->]");
                    OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
                }
            }
            if (choice == 5) {
                new SonIdMetier = clientIdMetier[client][0][0];
                if (inList(SonIdMetier, listMetierChef, 17)) {
                    decl String:bossSteamId[32];
                    GetClientAuthString(client, bossSteamId, 32);
                    decl String:clientName[32];
                    GetClientName(client, clientName, 32);
                    decl String:error[256];
                    if (!selectSalaire) {
                        selectSalaire = SQL_PrepareQuery(db, "SELECT st_job1, st_job2, st_job3, st_job4 FROM Bossjob WHERE st_job0 = ?", error, 256);
                        if (selectSalaire) {
                        } else {
                            Log("Roleplay FReZ", "Il y a une erreur dans la preparation de la requete pour selectSalaire NpcPrincipal (error: %s)", error);
                            return 0;
                        }
                    }
                    SQL_BindParamString(selectSalaire, 0, bossSteamId, false);
                    if (!SQL_Execute(selectSalaire)) {
                        Log("Roleplay FReZ", "Impossible de select les salari‚s pour definir salaire une personne (selectSalaire)");
                        return 0;
                    }
                    new Handle:g_MenuLeSalaire = CreateMenu(MenuHandler:67, MenuAction:28);
                    SetMenuTitle(g_MenuLeSalaire, "| D‚finir le Salaire de ? |\nAttention si votre capital est < 0 \nvous serez Sans Emploi !");
                    decl String:steamid[32];
                    decl String:sqlpseudo[256];
                    decl String:pseudo[40];
                    decl String:parametre[40];
                    decl String:buffer[40];
                    Format(parametre, 40, "0,%s", bossSteamId);
                    Format(buffer, 40, "%s", clientName);
                    AddMenuItem(g_MenuLeSalaire, parametre, buffer, 0);
                    if (SQL_FetchRow(selectSalaire)) {
                        new i = 0;
                        while (i < 4) {
                            SQL_FetchString(selectSalaire, i, steamid, 32, 0);
                            if (!StrEqual(steamid, "Aucun", true)) {
                                Format(sqlpseudo, 256, "SELECT pseudo FROM Player WHERE steamid='%s'", steamid);
                                new Handle:req2 = SQL_Query(db, sqlpseudo, -1);
                                if (req2) {
                                    if (SQL_FetchRow(req2)) {
                                        SQL_FetchString(req2, 0, pseudo, 40, 0);
                                        Format(parametre, 40, "%d,%s", i + 1, steamid);
                                        Format(buffer, 40, "%s", pseudo);
                                        AddMenuItem(g_MenuLeSalaire, parametre, buffer, 0);
                                    }
                                }
                                SQL_GetError(db, error, 256);
                                Log("RolePlay Admin", "Impossible de recuperer le pseudo du joueur a licencier (NPC Principal) ->erreur : %s", error);
                                return 0;
                            }
                            i++;
                        }
                    } else {
                        Log("RolePlay Admin", "Impossible de faire un select pour definir le salaire !!");
                    }
                    Format(parametre, 40, "9,aucun");
                    Format(buffer, 40, "Menu principal ");
                    AddMenuItem(g_MenuLeSalaire, parametre, buffer, 0);
                    DisplayMenu(g_MenuLeSalaire, client, 300);
                } else {
                    PrintToChat(client, "%s Vous ne pouvez pas modifier votre salaire ! *NPC Principal", "[Rp Magnetik : ->]");
                }
            }
            if (choice == 9) {
                OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
            }
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuLicencier(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[64];
    decl String:split[12][32];
    GetMenuItem(menu, choice, parametre, 64, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 32);
    new num = StringToInt(split[0][split], 10);
    decl String:steamid[32];
    Format(steamid, 32, "%s", split[4]);
    decl String:bossSteamId[32];
    GetClientAuthString(client, bossSteamId, 32);
    decl String:clientName[32];
    GetClientName(client, clientName, 32);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == 9) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        } else {
            decl String:sql[256];
            decl String:error[256];
            Format(sql, 256, "UPDATE Player SET team = 2, id_metier = 1, skins = 't_leet', vente_moi = 0, vente_annee = 0, salaire_sup = 0 WHERE steamid = '%s'", steamid);
            if (!SQL_FastQuery(db, sql, -1)) {
                SQL_GetError(db, error, 255);
                Log("Roleplay Admin", "Impossible de mettre par defaut un player licencier joueur -> Erreur : %s", error);
                return 0;
            }
            mettre_a_jour_joueur(steamid);
            if (!remettre_danslordre_jobboss(bossSteamId, num)) {
                Log("Roleplay Admin", "Impossible de decaler les joueur dans jobboss (remettre dans l'ordre)(licencier npc principal)");
                return 0;
            }
            Log("Roleplay Licencier", "%s de steam ID: %s a Licencier %s de steam ID: %s ", clientName, bossSteamId, split[8], steamid);
            PrintToChat(client, "%s Salari‚ Licencier ! *NPC Principal", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuLeSalaire(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[40];
    decl String:split[12][32];
    GetMenuItem(menu, choice, parametre, 40, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 32);
    new num = StringToInt(split[0][split], 10);
    decl String:steamid[32];
    Format(steamid, 32, "%s", split[4]);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == 9) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        } else {
            new Handle:g_MenuLesSalaires = CreateMenu(MenuHandler:69, MenuAction:28);
            SetMenuTitle(g_MenuLesSalaires, "| Quel salaire suppl‚mentaire ? |");
            decl String:param[40];
            Format(param, 40, "0,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "0 $ par jour", 0);
            Format(param, 40, "25,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "25 $ par jour", 0);
            Format(param, 40, "50,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "50 $ par jour", 0);
            Format(param, 40, "75,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "75 $ par jour", 0);
            Format(param, 40, "100,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "100 $ par jour", 0);
            Format(param, 40, "125,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "125 $ par jour", 0);
            Format(param, 40, "150,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "150 $ par jour", 0);
            Format(param, 40, "175,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "175 $ par jour", 0);
            Format(param, 40, "200,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "200 $ par jour", 0);
            Format(param, 40, "225,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "225 $ par jour", 0);
            Format(param, 40, "250,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "250 $ par jour", 0);
            Format(param, 40, "275,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "275 $ par jour", 0);
            Format(param, 40, "300,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "300 $ par jour", 0);
            Format(param, 40, "325,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "325 $ par jour", 0);
            Format(param, 40, "350,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "350 $ par jour", 0);
            Format(param, 40, "375,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "375 $ par jour", 0);
            Format(param, 40, "400,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "400 $ par jour", 0);
            Format(param, 40, "425,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "425 $ par jour", 0);
            Format(param, 40, "450,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "450 $ par jour", 0);
            Format(param, 40, "475,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "475 $ par jour", 0);
            Format(param, 40, "500,%s", steamid);
            AddMenuItem(g_MenuLesSalaires, param, "500 $ par jour", 0);
            DisplayMenu(g_MenuLesSalaires, client, 300);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuLesSalaires(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[40];
    decl String:split[12][32];
    GetMenuItem(menu, choice, parametre, 40, 0, "", 0);
    ExplodeString(parametre, ",", split, 3, 32);
    new num = StringToInt(split[0][split], 10);
    decl String:steamid[32];
    Format(steamid, 32, "%s", split[4]);
    if (ProcheJoueurPorte(1322, client)) {
        DonnerUnSalaireSup(steamid, num);
        PrintToChat(client, "%s Le salaire de %d $ … bien ‚tais d‚finie *NPC Principal", "[Rp Magnetik : ->]", num);
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuDemissionner(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (ProcheJoueurPorte(1322, client)) {
        if (num == 1) {
            new SonIdMetier = clientIdMetier[client][0][0];
            if (SonIdMetier != 1) {
                if (inList(SonIdMetier, listMetierChef, 17)) {
                    if (DetientUnMagasin(client)) {
                        new numero = NumeroDuMagasinDetenu(client);
                        if (numero != -1) {
                            FinDeLocationUnMagasin(numero);
                        }
                    }
                    DemissionerMetierBoss(client);
                    PrintToChat(client, "%s Vous ˆtes maintenant sans emploi... *NPC Principal", "[Rp Magnetik : ->]");
                    strcopy(clientSkin[client][0][0], 32, "t_leet");
                    DonnerUnSkinJoueur(client);
                    decl String:clientName[32];
                    GetClientName(client, clientName, 32);
                    decl String:steamid[32];
                    GetClientAuthString(client, steamid, 32);
                    Log("Roleplay d‚mission", "%s … d‚missionner de son job (metier boss : %s) Steam : %s ", clientName, metierNom[SonIdMetier][0][0], steamid);
                } else {
                    if (inList(SonIdMetier, listMetierSimple, 18)) {
                        DemissionerMetierSimple(client);
                        PrintToChat(client, "%s Vous ˆtes maintenant sans emploi... *NPC Principal", "[Rp Magnetik : ->]");
                        strcopy(clientSkin[client][0][0], 32, "t_leet");
                        DonnerUnSkinJoueur(client);
                        decl String:clientName[32];
                        GetClientName(client, clientName, 32);
                        decl String:steamid[32];
                        GetClientAuthString(client, steamid, 32);
                        Log("Roleplay d‚mission", "%s … d‚missionner de son job (metier simple : %s) Steam : %s ", clientName, metierNom[SonIdMetier][0][0], steamid);
                    }
                    PrintToChat(client, "%s Il faut l'accord du chef d'‚tat pour d‚missionner *NPC Principal", "[Rp Magnetik : ->]");
                }
            } else {
                PrintToChat(client, "%s Vous ˆtes d‚j… sans emploi ! *NPC Principal", "[Rp Magnetik : ->]");
            }
        } else {
            if (num == 2) {
                PrintToChat(client, "%s Vous avez refus‚ de d‚missionner *NPC Principal", "[Rp Magnetik : ->]");
            }
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelMetierExistant(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 9) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelLeRoleplay(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 9) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelCommande(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 8) {
            OpenMenu(client, panelCommande1, MenuHandler:155);
        } else {
            if (choice == 9) {
                OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
            }
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockpanelCommande1(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 9) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

AfficherInformationJoueur(client)
{
    new SonIdMetier = clientIdMetier[client][0][0];
    new var1;
    if (SonIdMetier == 23) {
        if (viseJoueur(client)) {
            new LeClient = GetClientAimTarget(client, true);
            if (LeClient != -1) {
                decl String:nameTarget[32];
                GetClientName(LeClient, nameTarget, 32);
                new Handle:g_MenuInfoDetective = CreateMenu(MenuHandler:59, MenuAction:28);
                decl String:titre[1024];
                Format(titre, 1024, "| Information Joueur |\nNom : %s\nTir Secondaire : %d\nTir primaire : %d\nCash : %d\nBank : %d\nLevel Knife %d/100\nDernier qu'il a tu‚ :\n%s\nDernier qu'il la tu‚ :\n%s", nameTarget, clientPermiSec[LeClient], clientPermiPri[LeClient], clientCash[LeClient], clientBank[LeClient], clientLevelKnife[LeClient], clientJaiTuer[LeClient][0][0], clientMaTuer[LeClient][0][0]);
                SetMenuTitle(g_MenuInfoDetective, titre);
                AddMenuItem(g_MenuInfoDetective, "1", "-> Quitter", 0);
                DisplayMenu(g_MenuInfoDetective, client, 300);
            }
        }
        PrintToChat(client, "%s Vous n'avez pas vis‚ quelqu'un ou vous ‚tes trop loin !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockMenuInfoDetective(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[4];
    GetMenuItem(menu, choice, parametre, 4, 0, "", 0);
    new valeur = StringToInt(parametre, 10);
    if (valeur == 1) {
        PrintToChat(client, "%s Fin des informations priv‚es !", "[Rp Magnetik : ->]");
    }
    return 0;
}

TelechargerSkins()
{
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_arms.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_blingbling.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_blingbling_belt.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_blingbling_belt_phong.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_body.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_body.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_body_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_body_exp.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_bullets.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_cap.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_clips.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_eyes.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_eyes.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_eyes_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_eyes_phong.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_head.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_head.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_head_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_head_exp.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_nades.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_nades_metal.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_phong.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_watch.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_watch_glass.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/50cent/slow_watch_glass.vtf");
    AddFileToDownloadsTable("models/player/slow/50cent/slow.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/50cent/slow.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/50cent/slow.mdl");
    AddFileToDownloadsTable("models/player/slow/50cent/slow.phy");
    AddFileToDownloadsTable("models/player/slow/50cent/slow.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/50cent/slow.vvd");
    AddFileToDownloadsTable("materials/models/player/slow/vin_diesel/slow_body.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/vin_diesel/slow_body.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/vin_diesel/slow_body_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/vin_diesel/slow_eye.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/vin_diesel/slow_eye.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/vin_diesel/slow_face.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/vin_diesel/slow_face_bump.vtf");
    AddFileToDownloadsTable("models/player/slow/vin_diesel/slow.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/vin_diesel/slow.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/vin_diesel/slow.mdl");
    AddFileToDownloadsTable("models/player/slow/vin_diesel/slow.phy");
    AddFileToDownloadsTable("models/player/slow/vin_diesel/slow.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/vin_diesel/slow.vvd");
    AddFileToDownloadsTable("models/player/slow/jknies/bloodz/slow_2.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/jknies/bloodz/slow_2.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/jknies/bloodz/slow_2.mdl");
    AddFileToDownloadsTable("models/player/slow/jknies/bloodz/slow_2.phy");
    AddFileToDownloadsTable("models/player/slow/jknies/bloodz/slow_2.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/jknies/bloodz/slow_2.vvd");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_1.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_1.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_1_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_2.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_2.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_2_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_3.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_3.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_3_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_mask.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_mask.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_mask_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx_2.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx_2.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx_logo.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx_logo.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx_logo_2.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/bloodz/slow_soldierx_logo_bump.vtf");
    AddFileToDownloadsTable("models/player/slow/jknies/cripz/slow_2.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/jknies/cripz/slow_2.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/jknies/cripz/slow_2.mdl");
    AddFileToDownloadsTable("models/player/slow/jknies/cripz/slow_2.phy");
    AddFileToDownloadsTable("models/player/slow/jknies/cripz/slow_2.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/jknies/cripz/slow_2.vvd");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_1.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_1.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_2.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_2.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_3.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_3.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_3_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_cap.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_cap.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_cap_2.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_cap_2.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_cap_2_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_cap_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_mask.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/jknies/cripz/slow_mask.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_eyes.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_fingernails.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_hair.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_hair.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_hair_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_hands.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_hands.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_hands_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_head.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_head.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_head_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_jacket.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_jacket.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_jacket_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_pants.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_pants.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_pants_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_shoes.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_shoes.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_shoes_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_teeth.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_teeth.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/niko_bellic/slow_teeth_bump.vtf");
    AddFileToDownloadsTable("models/player/slow/niko_bellic/slow.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/niko_bellic/slow.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/niko_bellic/slow.mdl");
    AddFileToDownloadsTable("models/player/slow/niko_bellic/slow.phy");
    AddFileToDownloadsTable("models/player/slow/niko_bellic/slow.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/niko_bellic/slow.vvd");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_dress.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_dress.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_dress_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_eyes.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_hair.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_hair.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_hair_fix.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_lashes.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_lashes.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_legs.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_legs.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_legs_bump.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_skin.vmt");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_skin.vtf");
    AddFileToDownloadsTable("materials/models/player/slow/aot/murray/slow_skin_bump.vtf");
    AddFileToDownloadsTable("models/player/slow/aot/murray/slow.dx80.vtx");
    AddFileToDownloadsTable("models/player/slow/aot/murray/slow.dx90.vtx");
    AddFileToDownloadsTable("models/player/slow/aot/murray/slow.mdl");
    AddFileToDownloadsTable("models/player/slow/aot/murray/slow.phy");
    AddFileToDownloadsTable("models/player/slow/aot/murray/slow.sw.vtx");
    AddFileToDownloadsTable("models/player/slow/aot/murray/slow.vvd");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/body.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/body.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/body_n.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/face.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/face.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/face_n.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/hair.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/hair.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/hotdonna/hair_n.vtf");
    AddFileToDownloadsTable("models/player/techknow/hotdonna/donna.dx80.vtx");
    AddFileToDownloadsTable("models/player/techknow/hotdonna/donna.dx90.vtx");
    AddFileToDownloadsTable("models/player/techknow/hotdonna/donna.mdl");
    AddFileToDownloadsTable("models/player/techknow/hotdonna/donna.phy");
    AddFileToDownloadsTable("models/player/techknow/hotdonna/donna.sw.vtx");
    AddFileToDownloadsTable("models/player/techknow/hotdonna/donna.vvd");
    AddFileToDownloadsTable("materials/models/player/elis/po/cleaner_face_e.vmt");
    AddFileToDownloadsTable("materials/models/player/elis/po/Cleaner_Face_E.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/po/Cleaner_Face_E_n.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/po/Estuche.vmt");
    AddFileToDownloadsTable("materials/models/player/elis/po/Estuche.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/po/Hand_White_A.vmt");
    AddFileToDownloadsTable("materials/models/player/elis/po/Hand_White_A.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/po/Hand_White_A_n.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/po/NYPD_Body_A_Coat.vmt");
    AddFileToDownloadsTable("materials/models/player/elis/po/NYPD_Body_A_Coat.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/po/NYPD_Body_A_Coat_n.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/po/NYPD_Legs_A.vmt");
    AddFileToDownloadsTable("materials/models/player/elis/po/NYPD_Legs_A.vtf");
    AddFileToDownloadsTable("materials/models/player/elis/po/NYPD_Legs_A_n.vtf");
    AddFileToDownloadsTable("models/player/elis/po/police.dx80.vtx");
    AddFileToDownloadsTable("models/player/elis/po/police.dx90.vtx");
    AddFileToDownloadsTable("models/player/elis/po/police.mdl");
    AddFileToDownloadsTable("models/player/elis/po/police.phy");
    AddFileToDownloadsTable("models/player/elis/po/police.sw.vtx");
    AddFileToDownloadsTable("models/player/elis/po/police.vvd");
    AddFileToDownloadsTable("models/player/pil/re1/wesker/wesker_pil.mdl");
    AddFileToDownloadsTable("models/player/pil/re1/wesker/wesker_pil.dx80.vtx");
    AddFileToDownloadsTable("models/player/pil/re1/wesker/wesker_pil.dx90.vtx");
    AddFileToDownloadsTable("models/player/pil/re1/wesker/wesker_pil.phy");
    AddFileToDownloadsTable("models/player/pil/re1/wesker/wesker_pil.sw.vtx");
    AddFileToDownloadsTable("models/player/pil/re1/wesker/wesker_pil.vvd");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/boots.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/boots.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/face.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/face.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/glass.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/glass.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/hand.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/hand.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/mano.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/mano.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/ojo.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/ojo.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/pant.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/pant.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/pelo.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/pelo.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/stars.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/stars.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/thingys.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/thingys.vmt");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/vest.vtf");
    AddFileToDownloadsTable("materials/models/player/pil/re1/wesker/vest.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/greaser/greaser.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/greaser/greaser.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/greaser/greaser_n.vtf");
    AddFileToDownloadsTable("models/player/techknow/greaser/greaser.dx80.vtx");
    AddFileToDownloadsTable("models/player/techknow/greaser/greaser.dx90.vtx");
    AddFileToDownloadsTable("models/player/techknow/greaser/greaser.mdl");
    AddFileToDownloadsTable("models/player/techknow/greaser/greaser.phy");
    AddFileToDownloadsTable("models/player/techknow/greaser/greaser.sw.vtx");
    AddFileToDownloadsTable("models/player/techknow/greaser/greaser.vvd");
    AddFileToDownloadsTable("models/player/natalya/civilians/male_chef.dx80.vtx");
    AddFileToDownloadsTable("models/player/natalya/civilians/male_chef.dx90.vtx");
    AddFileToDownloadsTable("models/player/natalya/civilians/male_chef.mdl");
    AddFileToDownloadsTable("models/player/natalya/civilians/male_chef.phy");
    AddFileToDownloadsTable("models/player/natalya/civilians/male_chef.sw.vtx");
    AddFileToDownloadsTable("models/player/natalya/civilians/male_chef.vvd");
    AddFileToDownloadsTable("models/player/natalya/civilians/male_chef.xbox.vtx");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/sandro_facemap.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/sandro_facemap.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/sandro_facemap_n.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/chef.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/chef.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/chef_n.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/eyeball_l.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/eyeball_l.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/eyeball_r.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/civilians/eyeball_r.vtf");
    return 0;
}

PreChargerLesSkins()
{
    PrecacheModel("models/player/t_leet.mdl", true);
    PrecacheModel("models/player/ct_sas.mdl", true);
    PrecacheModel("models/player/slow/50cent/slow.mdl", true);
    PrecacheModel("models/player/slow/vin_diesel/slow.mdl", true);
    PrecacheModel("models/player/slow/jknies/bloodz/slow_2.mdl", true);
    PrecacheModel("models/player/slow/jknies/cripz/slow_2.mdl", true);
    PrecacheModel("models/player/slow/niko_bellic/slow.mdl", true);
    PrecacheModel("models/player/slow/aot/murray/slow.mdl", true);
    PrecacheModel("models/player/techknow/hotdonna/donna.mdl", true);
    PrecacheModel("models/player/elis/po/police.mdl", true);
    PrecacheModel("models/player/pil/re1/wesker/wesker_pil.mdl", true);
    PrecacheModel("models/player/techknow/greaser/greaser.mdl", true);
    PrecacheModel("models/player/natalya/civilians/male_chef.mdl", true);
    return 0;
}

DonnerUnSkinJoueur(client)
{
    decl String:skins[128];
    if (StrEqual(clientSkin[client][0][0], "t_leet", true)) {
        Format(skins, 128, "models/player/t_leet.mdl");
        if (!IsModelPrecached(skins)) {
            PrecacheModel(skins, true);
        }
        SetEntityModel(client, skins);
    } else {
        if (StrEqual(clientSkin[client][0][0], "ct_sas", true)) {
            Format(skins, 128, "models/player/ct_sas.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "civilians", true)) {
            Format(skins, 128, "models/player/natalya/civilians/male_chef.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "greaser", true)) {
            Format(skins, 128, "models/player/techknow/greaser/greaser.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "wesker", true)) {
            Format(skins, 128, "models/player/pil/re1/wesker/wesker_pil.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "police", true)) {
            Format(skins, 128, "models/player/elis/po/police.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "50cent", true)) {
            Format(skins, 128, "models/player/slow/50cent/slow.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "vin_diesel", true)) {
            Format(skins, 128, "models/player/slow/vin_diesel/slow.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "bloodz", true)) {
            Format(skins, 128, "models/player/slow/jknies/bloodz/slow_2.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "cripz", true)) {
            Format(skins, 128, "models/player/slow/jknies/cripz/slow_2.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "niko_bellic", true)) {
            Format(skins, 128, "models/player/slow/niko_bellic/slow.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "hotdonna", true)) {
            Format(skins, 128, "models/player/techknow/hotdonna/donna.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
        if (StrEqual(clientSkin[client][0][0], "murray", true)) {
            Format(skins, 128, "models/player/slow/aot/murray/slow.mdl");
            if (!IsModelPrecached(skins)) {
                PrecacheModel(skins, true);
            }
            SetEntityModel(client, skins);
        }
    }
    SetEntPropEnt(client, PropType:0, "m_hObserverTarget", 0);
    SetEntProp(client, PropType:0, "m_iObserverMode", any:1, 4);
    SetEntProp(client, PropType:0, "m_bDrawViewmodel", any:0, 4);
    SetEntProp(client, PropType:0, "m_iFOV", any:100, 4);
    CreateTimer(4, MettreALaPremierPersonne, client, 0);
    return 0;
}

public Action:MettreALaPremierPersonne(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        SetEntPropEnt(client, PropType:0, "m_hObserverTarget", -1);
        SetEntProp(client, PropType:0, "m_iObserverMode", any:0, 4);
        SetEntProp(client, PropType:0, "m_bDrawViewmodel", any:1, 4);
        SetEntProp(client, PropType:0, "m_iFOV", any:90, 4);
    }
    return Action:0;
}

SauvegarderLeSkinDB(client, String:leSkin[])
{
    decl String:req[512];
    decl String:error[256];
    decl String:steamId[256];
    GetClientAuthString(client, steamId, 255);
    Format(req, 512, "UPDATE Player SET skins = '%s' WHERE steamid = '%s'", leSkin, steamId);
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de update le skins (SauvegarderLeSkinDB) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}


/* ERROR! unknown operator */
 function "indexZoneDuJoueur" (number 302)
SortirJoueurDuPlanque(client)
{
    new zone = indexZoneDuJoueur(client);
    new var1;
    if (zone) {
        PrintToChat(client, "%s Vous ne pouvez pas utilis‚ !out dans cette zone !", "[Rp Magnetik : ->]");
    } else {
        decl String:steamId[32];
        GetClientAuthString(client, steamId, 32);
        new idMetier = clientIdMetier[client][0][0];
        new indexPorte = indexPorteZone[zone][0][0];
        new var2;
        if (JoueurProprio(indexPorte, steamId)) {
            new clientTarget = GetClientAimTarget(client, true);
            if (clientTarget == -1) {
                PrintToChat(client, "%s Vous n'avez pas vis‚ quelqu'un !", "[Rp Magnetik : ->]");
            } else {
                decl String:steamIdTarget[32];
                GetClientAuthString(clientTarget, steamIdTarget, 32);
                new idMetierTarget = clientIdMetier[clientTarget][0][0];
                new var3;
                if (JoueurProprio(indexPorte, steamIdTarget)) {
                    PrintToChat(client, "%s Le citoyen que vous vis‚ est propri‚taire !", "[Rp Magnetik : ->]");
                } else {
                    new var4;
                    if (idMetierTarget == 2) {
                        PrintToChat(client, "%s Le citoyen que vous vis‚ est un agent de s‚curit‚ !", "[Rp Magnetik : ->]");
                    }
                    new zoneTarget = indexZoneDuJoueur(clientTarget);
                    if (zone != zoneTarget) {
                        PrintToChat(client, "%s Le citoyen que vous vis‚ est pas dans la mˆme zone que vous !", "[Rp Magnetik : ->]");
                    } else {
                        TeleportEntity(clientTarget, zoneDeTelePort[zone][0][0], NULL_VECTOR, NULL_VECTOR);
                        PrintToChat(client, "%s Le citoyen est sortie !", "[Rp Magnetik : ->]");
                        PrintToChat(clientTarget, "%s Dehors !", "[Rp Magnetik : ->]");
                    }
                }
            }
        } else {
            PrintToChat(client, "%s Vous n'‚tes pas propri‚taire !", "[Rp Magnetik : ->]");
        }
    }
    return 0;
}

inserLesZone()
{
    new i = 0;
    Format(nomZones[i][0][0], 32, "Ext‚rieur");
    new var1 = listZones[i][0][0];
    var1[0][var1] = 0;
    new var2 = listZones[i][0][0];
    var2[0][var2][4] = 0;
    new var3 = listZones[i][0][0];
    var3[0][var3][8] = 0;
    listZones[i][0][0][4] = 0;

/* ERROR! unknown load */
 function "inserLesZone" (number 304)
public Action:TickSecond(Handle:timer)
{
    display();
    VerificationLocation();
    VerificationLocationAppartement();
    VerificationPlayerEmpoissone();
    DeclancherTelephone();
    VerifTimePourEvent();
    if (EventGuerre) {
        VerificationJoueurEvent();
    }
    return Action:0;
}


/* ERROR! unknown operator */
 function "display" (number 306)
DonneLaPaye()
{
    new i = 1;
    new SonIdMetier = 0;
    new salaireSupS = 0;
    decl String:steamId[32];
    decl String:req[512];
    decl String:error[256];
    new Handle:query2 = 0;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            if (!clientInJail[i][0][0]) {
                SonIdMetier = clientIdMetier[i][0][0];
                if (inList(SonIdMetier, listMetiersSpe, 5)) {
                    if (clientRibe[i][0][0]) {
                        new var2 = clientBank[i];
                        var2 = metierFric[clientIdMetier[i][0][0]][0][0] + var2[0][0];
                    } else {
                        new var3 = clientCash[i];
                        var3 = metierFric[clientIdMetier[i][0][0]][0][0] + var3[0][0];
                    }
                    EnleverArgentALaTG(metierFric[clientIdMetier[i][0][0]][0][0]);
                    PrintToChat(i, "%s Tu viens de recevoir ta paye de : %d $ de l'‚tat !", "[Rp Magnetik : ->]", metierFric[clientIdMetier[i][0][0]]);
                } else {
                    GetClientAuthString(i, steamId, 32);
                    salaireSupS = 0;
                    Format(req, 512, "SELECT salaire_sup FROM Player WHERE steamid = '%s'", steamId);
                    query2 = SQL_Query(db, req, -1);
                    if (!query2) {
                        SQL_GetError(db, error, 255);
                        Log("Roleplay Salaire", "Impossible de select le salaire sup dans (DonneLaPaye)-> error: %s", error);
                    }
                    if (SQL_FetchRow(query2)) {
                        salaireSupS = SQL_FetchInt(query2, 0, 0);
                    } else {
                        Log("Roleplay Capital", "Impossible de select salaire sup qd sql fetch row");
                    }
                    if (salaireSupS) {
                        Format(req, 512, "UPDATE Bossjob SET capital_groupe = capital_groupe - %d WHERE st_job0 = '%s' OR st_job1 = '%s' OR st_job2 = '%s' OR st_job3 = '%s' OR st_job4 = '%s' ", salaireSupS, steamId, steamId, steamId, steamId, steamId);
                        if (!SQL_FastQuery(db, req, -1)) {
                            SQL_GetError(db, error, 255);
                            Log("Roleplay Salaire", "Impossible update dans la table bossjob la soustraction du salaire (DonneLaPaye) -> Erreur : %s", error);
                            if (clientRibe[i][0][0]) {
                                new var6 = clientBank[i];
                                var6 = metierFric[clientIdMetier[i][0][0]][0][0] + var6[0][0];
                            } else {
                                new var7 = clientCash[i];
                                var7 = metierFric[clientIdMetier[i][0][0]][0][0] + var7[0][0];
                            }
                            PrintToChat(i, "%s Tu viens de recevoir ta paye de : %d $", "[Rp Magnetik : ->]", metierFric[clientIdMetier[i][0][0]]);
                        }
                        if (clientRibe[i][0][0]) {
                            new var8 = clientBank[i];
                            var8 = metierFric[clientIdMetier[i][0][0]][0][0] + salaireSupS + var8[0][0];
                        } else {
                            new var9 = clientCash[i];
                            var9 = metierFric[clientIdMetier[i][0][0]][0][0] + salaireSupS + var9[0][0];
                        }
                        PrintToChat(i, "%s Tu viens de recevoir ta paye de : %d $ + %d $ du capital !", "[Rp Magnetik : ->]", metierFric[clientIdMetier[i][0][0]], salaireSupS);
                        VerifierLeCapital(steamId);
                    }
                    if (clientRibe[i][0][0]) {
                        new var4 = clientBank[i];
                        var4 = metierFric[clientIdMetier[i][0][0]][0][0] + var4[0][0];
                    } else {
                        new var5 = clientCash[i];
                        var5 = metierFric[clientIdMetier[i][0][0]][0][0] + var5[0][0];
                    }
                    PrintToChat(i, "%s Tu viens de recevoir ta paye de : %d $", "[Rp Magnetik : ->]", metierFric[clientIdMetier[i][0][0]]);
                }
            }
            PrintToChat(i, "%s Tu ne re‡ois pas ta paye, car tu es en prison !", "[Rp Magnetik : ->]");
        }
        i++;
    }
    return 0;
}

LevelKnifeUser()
{
    new i = 1;
    new SonIdMetier = 0;
    while (i <= MaxClients) {
        new var1;
        if (IsClientInGame(i)) {
            SonIdMetier = clientIdMetier[i][0][0];
            if (!inList(SonIdMetier, listMetierSecu, 4)) {
                if (clientLevelKnife[i][0][0] > 1) {
                    new var2 = clientLevelKnife[i];
                    var2 = var2[0][0] + -2;
                }
                if (0 < clientPrecision[i][0][0]) {
                    new var3 = clientPrecision[i];
                    var3 = var3[0][0] + -1;
                }
            }
        }
        i++;
    }
    return 0;
}

AfficherRecetteChefEntreprise(client)
{
    decl String:steamId[32];
    GetClientAuthString(client, steamId, 32);
    decl String:req[512];
    decl String:error[256];
    Format(req, 512, "SELECT vente_moi, vente_annee, salaire_sup FROM Player WHERE steamid = '%s'", steamId);
    new Handle:query = SQL_Query(db, req, -1);
    if (query) {
        new venteMoiBoss = 0;
        new venteAnneeBoss = 0;
        new salaireSup = 0;
        if (SQL_FetchRow(query)) {
            venteMoiBoss = SQL_FetchInt(query, 0, 0);
            venteAnneeBoss = SQL_FetchInt(query, 1, 0);
            salaireSup = SQL_FetchInt(query, 2, 0);
            new Handle:panelRecette = CreatePanel(Handle:0);
            SetPanelTitle(panelRecette, "| Vos Recette |", false);
            SetPanelKeys(panelRecette, 1023);
            DrawPanelText(panelRecette, " ");
            if (!selectRecette) {
                selectRecette = SQL_PrepareQuery(db, "SELECT capital_groupe, st_job1, st_job2, st_job3, st_job4, vente_npc_moi, vente_npc_annee, impot FROM Bossjob WHERE st_job0 = ?", error, 255);
                if (selectRecette) {
                } else {
                    Log("Roleplay Capital", "Impossible de preparer la requette pour le capital (npcprincipal.sp)-> error: %s", error);
                    return 0;
                }
            }
            SQL_BindParamString(selectRecette, 0, steamId, false);
            if (!SQL_Execute(selectRecette)) {
                Log("Roleplay Capital", "Impossible de select le capital + les salarier dans bossjob");
                return 0;
            }
            if (SQL_FetchRow(selectRecette)) {
                new capital = SQL_FetchInt(selectRecette, 0, 0);
                new npcmoi = SQL_FetchInt(selectRecette, 5, 0);
                new npcannee = SQL_FetchInt(selectRecette, 6, 0);
                new impot = SQL_FetchInt(selectRecette, 7, 0);
                decl String:texte[60];
                Format(texte, 60, "Capital : %d $", capital);
                DrawPanelText(panelRecette, texte);
                Format(texte, 60, "Impots : %d $", impot);
                DrawPanelText(panelRecette, texte);
                Format(texte, 60, "Le boss : %s", clientPseudo[client][0][0]);
                DrawPanelText(panelRecette, texte);
                Format(texte, 60, "Vente par mois : %d $", venteMoiBoss);
                DrawPanelText(panelRecette, texte);
                Format(texte, 60, "Vente par ann‚e : %d $", venteAnneeBoss);
                DrawPanelText(panelRecette, texte);
                Format(texte, 60, "Salaire : %d $ / jour", salaireSup);
                DrawPanelText(panelRecette, texte);
                decl String:steamIdSal[32];
                decl String:pseudo[32];
                new salaireSupS = 0;
                new vente_moi = 0;
                new vente_annee = 0;
                new i = 1;
                while (i < 5) {
                    SQL_FetchString(selectRecette, i, steamIdSal, 32, 0);
                    if (!StrEqual(steamIdSal, "Aucun", true)) {
                        Format(req, 512, "SELECT pseudo, salaire_sup, vente_moi, vente_annee FROM Player WHERE steamid = '%s'", steamIdSal);
                        new Handle:query2 = SQL_Query(db, req, -1);
                        if (query2) {
                            if (SQL_FetchRow(query2)) {
                                SQL_FetchString(query2, 0, pseudo, 32, 0);
                                salaireSupS = SQL_FetchInt(query2, 1, 0);
                                vente_moi = SQL_FetchInt(query2, 2, 0);
                                vente_annee = SQL_FetchInt(query2, 3, 0);
                                Format(texte, 60, "Nom: %s", pseudo);
                                DrawPanelText(panelRecette, texte);
                                Format(texte, 60, "Vente par mois : %d $", vente_moi);
                                DrawPanelText(panelRecette, texte);
                                Format(texte, 60, "Vente par ann‚e : %d $", vente_annee);
                                DrawPanelText(panelRecette, texte);
                                Format(texte, 60, "Salaire : %d $ / jour", salaireSupS);
                                DrawPanelText(panelRecette, texte);
                            }
                            Log("Roleplay Capital", "Impossible de select vente moi et vente annee du boss qd sql fetch row");
                            return 0;
                        }
                        SQL_GetError(db, error, 255);
                        Log("Roleplay Capital", "Impossible de select pseudo ,salaire sup ,vente d'un salarie-> error: %s", error);
                        return 0;
                    }
                    i++;
                }
                Format(texte, 60, "Vente NPC au mois : %d $", npcmoi);
                DrawPanelText(panelRecette, texte);
                Format(texte, 60, "Vente NPC au ann‚e : %d $", npcannee);
                DrawPanelText(panelRecette, texte);
                DrawPanelText(panelRecette, "->9. Menu Principal");
                OpenMenu(client, panelRecette, MenuHandler:173);
            }
            return 0;
        }
        Log("Roleplay Capital", "Impossible de select vente moi et vente annee du boss qd sql fetch row");
        return 0;
    }
    SQL_GetError(db, error, 255);
    Log("Roleplay Capital", "Impossible de select vente moi et vente annee du boss-> error: %s", error);
    return 0;
}

public BlockpanelRecette(Handle:menu, MenuAction:action, client, choice)
{
    new var1;
    if (action == MenuAction:4) {
        return 0;
    }
    if (ProcheJoueurPorte(1322, client)) {
        if (choice == 9) {
            OpenMenu(client, panelNpcPrincipale, MenuHandler:171);
        }
    } else {
        PrintToChat(client, "%s Vous ˆtes trop loin du NPC !", "[Rp Magnetik : ->]");
    }
    return 0;
}

AfficherRecetteSalarier(client)
{
    decl String:steamId[32];
    GetClientAuthString(client, steamId, 32);
    new Handle:panelRecette = CreatePanel(Handle:0);
    SetPanelTitle(panelRecette, "| Vos Recette |", false);
    SetPanelKeys(panelRecette, 1023);
    DrawPanelText(panelRecette, " ");
    decl String:error[256];
    if (!selectRecetteSal) {
        selectRecetteSal = SQL_PrepareQuery(db, "SELECT capital_groupe, vente_npc_moi, vente_npc_annee, st_job0, st_job1, st_job2, st_job3, st_job4, impot FROM Bossjob WHERE st_job1 = ? OR st_job2 = ? OR st_job3 = ? OR st_job4 = ?", error, 255);
        if (selectRecetteSal) {
        } else {
            Log("RolePlay Capital", "Impossible de preparer la requette de (AfficherRecetteSalarierEntreprise()) ->erreur : %s", error);
            return 0;
        }
    }
    SQL_BindParamString(selectRecetteSal, 0, steamId, false);
    SQL_BindParamString(selectRecetteSal, 1, steamId, false);
    SQL_BindParamString(selectRecetteSal, 2, steamId, false);
    SQL_BindParamString(selectRecetteSal, 3, steamId, false);
    if (!SQL_Execute(selectRecetteSal)) {
        Log("Roleplay Capital", "Impossible de select tous les steam id (AfficherRecetteSalarierEntreprise)");
        return 0;
    }
    if (SQL_FetchRow(selectRecetteSal)) {
        new capital = SQL_FetchInt(selectRecetteSal, 0, 0);
        new npcmoi = SQL_FetchInt(selectRecetteSal, 1, 0);
        new npcannee = SQL_FetchInt(selectRecetteSal, 2, 0);
        new impot = SQL_FetchInt(selectRecetteSal, 8, 0);
        decl String:texte[60];
        Format(texte, 60, "Capital : %d $", capital);
        DrawPanelText(panelRecette, texte);
        Format(texte, 60, "Impots : %d $", impot);
        DrawPanelText(panelRecette, texte);
        decl String:steamIdSal[32];
        decl String:pseudo[32];
        decl String:req[512];
        new salaireSupS = 0;
        new vente_moi = 0;
        new vente_annee = 0;
        new i = 3;
        while (i < 8) {
            SQL_FetchString(selectRecetteSal, i, steamIdSal, 32, 0);
            if (!StrEqual(steamIdSal, "Aucun", true)) {
                Format(req, 512, "SELECT pseudo, salaire_sup, vente_moi, vente_annee FROM Player WHERE steamid = '%s'", steamIdSal);
                new Handle:query2 = SQL_Query(db, req, -1);
                if (query2) {
                    if (SQL_FetchRow(query2)) {
                        SQL_FetchString(query2, 0, pseudo, 32, 0);
                        salaireSupS = SQL_FetchInt(query2, 1, 0);
                        vente_moi = SQL_FetchInt(query2, 2, 0);
                        vente_annee = SQL_FetchInt(query2, 3, 0);
                        if (i == 3) {
                            Format(texte, 60, "Boss: %s", pseudo);
                            DrawPanelText(panelRecette, texte);
                        } else {
                            Format(texte, 60, "Nom: %s", pseudo);
                            DrawPanelText(panelRecette, texte);
                        }
                        Format(texte, 60, "Vente par mois: %d $", vente_moi);
                        DrawPanelText(panelRecette, texte);
                        Format(texte, 60, "Vente par ann‚e: %d $", vente_annee);
                        DrawPanelText(panelRecette, texte);
                        Format(texte, 60, "Salaire: %d $ / jour", salaireSupS);
                        DrawPanelText(panelRecette, texte);
                    }
                    Log("Roleplay Capital", "Impossible de select vente moi et vente annee du boss qd sql fetch row");
                    return 0;
                }
                SQL_GetError(db, error, 255);
                Log("Roleplay Capital", "Impossible de select pseudo ,salaire sup ,vente d'un salarie (AfficherRecetteSalarierEntreprise)-> error: %s", error);
                return 0;
            }
            i++;
        }
        Format(texte, 60, "Vente NPC au mois : %d $", npcmoi);
        DrawPanelText(panelRecette, texte);
        Format(texte, 60, "Vente NPC au ann‚e : %d $", npcannee);
        DrawPanelText(panelRecette, texte);
        DrawPanelText(panelRecette, "->9. Menu Principal");
        OpenMenu(client, panelRecette, MenuHandler:173);
        return 0;
    }
    Log("Roleplay Capital", "Impossible de select st_job 0 dans (DemissionerMetierSimple)");
    return 0;
}

AjouterArgentCapitalAchats(client, argent)
{
    decl String:steamId[32];
    GetClientAuthString(client, steamId, 32);
    new var1;
    if (clientIdMetier[client][0][0] == 35) {
        new capitalEnt = argent * 80 / 100;
        new ArgentJoueur = argent - capitalEnt;
        decl String:req[512];
        decl String:error[256];
        Format(req, 512, "UPDATE Bossjob SET capital_groupe = capital_groupe + %d  WHERE st_job0 = '%s' OR st_job1 = '%s' OR st_job2 = '%s' OR st_job3 = '%s' OR st_job4 = '%s' ", capitalEnt, steamId, steamId, steamId, steamId, steamId);
        if (!SQL_FastQuery(db, req, -1)) {
            SQL_GetError(db, error, 255);
            Log("Roleplay Capital", "Impossible ajouter + capital_groupe dans Bossjob (AjouterArgentCapitalAchatsMAfia) -> Erreur : %s", error);
            return 0;
        }
        Format(req, 512, "UPDATE Player SET vente_moi = vente_moi + %d , vente_annee = vente_annee + %d  WHERE steamid = '%s'", argent, argent, steamId);
        if (!SQL_FastQuery(db, req, -1)) {
            SQL_GetError(db, error, 255);
            Log("Roleplay Capital", "Impossible ajouter + vente mois et + vente annee dans player (AjouterArgentCapitalAchats) -> Erreur : %s", error);
            return 0;
        }
        if (clientRibe[client][0][0]) {
            new var2 = clientBank[client];
            var2 = var2[0][0] + ArgentJoueur;
        } else {
            new var3 = clientCash[client];
            var3 = var3[0][0] + ArgentJoueur;
        }
    } else {
        new capitalEnt = argent * 70 / 100;
        new tresorie = argent * 10 / 100;
        new ArgentJoueur = argent * 20 / 100;
        decl String:req[512];
        decl String:error[256];
        Format(req, 512, "UPDATE Capital SET total_capital = total_capital + %d WHERE id_capital = 1", tresorie);
        if (!SQL_FastQuery(db, req, -1)) {
            SQL_GetError(db, error, 255);
            Log("Roleplay Capital", "Impossible ajouter 10/100 au capital_total de la TG dans Capital (AjouterArgentCapitalAchats) -> Erreur : %s", error);
            return 0;
        }
        Format(req, 512, "UPDATE Bossjob SET capital_groupe = capital_groupe + %d, impot = impot + %d WHERE st_job0 = '%s' OR st_job1 = '%s' OR st_job2 = '%s' OR st_job3 = '%s' OR st_job4 = '%s' ", capitalEnt, tresorie, steamId, steamId, steamId, steamId, steamId);
        if (!SQL_FastQuery(db, req, -1)) {
            SQL_GetError(db, error, 255);
            Log("Roleplay Capital", "Impossible ajouter + capital_groupe dans Bossjob (AjouterArgentCapitalAchats) -> Erreur : %s", error);
            return 0;
        }
        Format(req, 512, "UPDATE Player SET vente_moi = vente_moi + %d , vente_annee = vente_annee + %d  WHERE steamid = '%s'", argent, argent, steamId);
        if (!SQL_FastQuery(db, req, -1)) {
            SQL_GetError(db, error, 255);
            Log("Roleplay Capital", "Impossible ajouter + vente mois et + vente annee dans player (AjouterArgentCapitalAchats) -> Erreur : %s", error);
            return 0;
        }
        if (clientRibe[client][0][0]) {
            new var4 = clientBank[client];
            var4 = var4[0][0] + ArgentJoueur;
        } else {
            new var5 = clientCash[client];
            var5 = var5[0][0] + ArgentJoueur;
        }
    }
    return 0;
}

AjouterArgentCapitalNPC(String:steamId[], argent)
{
    new capitalEnt = argent * 75 / 100;
    new tresorie = argent - capitalEnt;
    decl String:req[1024];
    decl String:error[256];
    Format(req, 1024, "UPDATE Bossjob SET capital_groupe = capital_groupe + %d, impot = impot + %d, vente_npc_moi = vente_npc_moi + %d, vente_npc_annee = vente_npc_annee + %d WHERE st_job0 = '%s'", capitalEnt, tresorie, argent, argent, steamId);
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible ajouter + capital_groupe dans Bossjob (AjouterArgentCapitalNPC) -> Erreur : %s", error);
        return 0;
    }
    Format(req, 1024, "UPDATE Capital SET total_capital = total_capital + %d WHERE id_capital = 1", tresorie);
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible ajouter 10/100 au capital_total de la TG dans Capital (AjouterArgentCapitalNPC) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}

VerifierLeCapital(String:steamId[])
{
    decl String:req[512];
    decl String:error[256];
    Format(req, 512, "SELECT capital_groupe, st_job0, st_job1, st_job2, st_job3, st_job4 FROM Bossjob WHERE st_job0 = '%s' OR st_job1 = '%s' OR st_job2 = '%s' OR st_job3 = '%s' OR st_job4 = '%s'", steamId, steamId, steamId, steamId, steamId);
    new Handle:query2 = SQL_Query(db, req, -1);
    if (query2) {
        new leCapital = 0;
        if (SQL_FetchRow(query2)) {
            leCapital = SQL_FetchInt(query2, 0, 0);
            if (0 > leCapital) {
                decl String:SteamIdSal[32];
                new i = 1;
                while (i < 6) {
                    SQL_FetchString(query2, i, SteamIdSal, 32, 0);
                    if (!StrEqual(SteamIdSal, "Aucun", true)) {
                        mettreJoueurConnecter(SteamIdSal);
                        Format(req, 512, "UPDATE Player SET team = 2, id_metier = 1, skins = 't_leet', vente_moi = 0, vente_annee = 0, salaire_sup = 0 WHERE steamid = '%s'", SteamIdSal);
                        if (!SQL_FastQuery(db, req, -1)) {
                            SQL_GetError(db, error, 255);
                            Log("RolePlay Capital", "Impossible de mettre un joueur sans emploi (VerifierLeCapital()) ->erreur : %s", error);
                        }
                    }
                    i++;
                }
                SQL_FetchString(query2, 1, SteamIdSal, 32, 0);
                if (!deleteUneEntrep) {
                    deleteUneEntrep = SQL_PrepareQuery(db, "DELETE FROM Bossjob WHERE Bossjob.st_job0 = ? ", error, 255);
                    if (deleteUneEntrep) {
                    } else {
                        Log("RolePlay Capital", "Impossible de preparer la requette pour delete le boss (VerifierLeCapital()) ->erreur : %s", error);
                        return 0;
                    }
                }
                SQL_BindParamString(deleteUneEntrep, 0, SteamIdSal, false);
                if (!SQL_Execute(deleteUneEntrep)) {
                    Log("Roleplay Capital", "Impossible de delete boss dans jobBoss (VerifierLeCapital)");
                    return 0;
                }
                return 0;
            }
            return 0;
        }
        Log("Roleplay Capital", "Impossible de select salaire sup qd sql fetch row (VerifierLeCapital)");
        return 0;
    }
    SQL_GetError(db, error, 255);
    Log("Roleplay Capital", "Impossible de select le capital et tout les st job (VerifierLeCapital)-> error: %s", error);
    return 0;
}

mettreJoueurConnecter(String:steamid[])
{
    decl String:clientSteamId[32];
    new client = 1;
    while (client <= MaxClients) {
        new var1;
        if (IsClientInGame(client)) {
            GetClientAuthString(client, clientSteamId, 32);
            if (StrEqual(clientSteamId, steamid, true)) {
                clientTeam[client] = 2;
                clientIdMetier[client] = 1;
                strcopy(clientSkin[client][0][0], 32, "t_leet");
                PrintToChat(client, "%s Vous ˆtes licencier, car votre entreprise … d‚poser le bilan (capital < 0) !", "[Rp Magnetik : ->]");
                client++;
            }
            client++;
        }
        client++;
    }
    return 0;
}

DonnerArgentALaTG(argent)
{
    decl String:req[512];
    decl String:error[256];
    Format(req, 512, "UPDATE Capital SET total_capital = total_capital + %d WHERE id_capital = 1", argent);
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de update le total capital add (DonnerArgentALaTG) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}

EnleverArgentALaTG(argent)
{
    decl String:req[512];
    decl String:error[256];
    Format(req, 512, "UPDATE Capital SET total_capital = total_capital - %d WHERE id_capital = 1", argent);
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de update le total capital soustraction  (EnleverArgentALaTG) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}

DonnerUnSalaireSup(String:steamid[], argent)
{
    decl String:req[512];
    decl String:error[256];
    Format(req, 512, "UPDATE Player SET salaire_sup = %d WHERE steamid = '%s' ", argent, steamid);
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de donner un salaire supplementaire (DonnerUnSalaireSup) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}

ChangementDeMois()
{
    decl String:req[256];
    decl String:error[256];
    Format(req, 255, "UPDATE Player SET vente_moi = 0");
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de remettre a zero le vente mois des joueurs (ChangementDeMois) -> Erreur : %s", error);
        return 0;
    }
    Format(req, 255, "UPDATE Bossjob SET vente_npc_moi = 0");
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de remettre a zero le vente mois dans bossjob (ChangementDeMois) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}

ChangementDAnnee()
{
    decl String:req[256];
    decl String:error[256];
    Format(req, 255, "UPDATE Player SET vente_annee = 0");
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de remettre a zero le vente Annee des joueurs (ChangementDAnnee) -> Erreur : %s", error);
        return 0;
    }
    Format(req, 255, "UPDATE Bossjob SET vente_npc_annee = 0");
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de remettre a zero le vente Annee des joueurs (ChangementDAnnee) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}

EnregistrerLesCapitaux()
{
    decl String:req[512];
    decl String:error[256];
    Format(req, 512, "UPDATE Capital SET Capital.total_capital = (SELECT SUM(Bossjob.capital_groupe) FROM Bossjob WHERE Capital.id_metier_assoc = Bossjob.id_metier GROUP BY Capital.id_metier_assoc) WHERE Capital.id_capital <> 1");
    if (!SQL_FastQuery(db, req, -1)) {
        SQL_GetError(db, error, 255);
        Log("Roleplay Capital", "Impossible de faire le update (EnregistrerLesCapitaux) -> Erreur : %s", error);
        return 0;
    }
    return 0;
}


/* ERROR! unknown operator */
 function "tazerUnJoueur" (number 322)
public Action:playerParDefault(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", 1);
    }
    return Action:0;
}

MettreArmeDansSacTazer(client)
{
    decl String:weapon[32];
    GetClientWeapon(client, weapon, 32);
    new bool:existe = 0;
    new slot = 0;
    if (armeList(weapon, armePrimaire, 6)) {
        existe = 1;
        slot = 1;
    } else {
        if (armeList(weapon, armeSecondaire, 17)) {
            existe = 1;
            slot = 0;
        }
        if (armeList(weapon, armeProjectile, 3)) {
            existe = 1;
            slot = 3;
        }
    }
    if (existe) {
        new bool:trouve = 0;
        new indexArme = 0;
        new index = 0;
        new item = 0;
        decl String:nomArme[64];
        while (index < 28 && trouve) {
            Format(nomArme, 64, "weapon_%s", objetNom[listObjetArmes[index][0][0]][0][0]);
            if (StrEqual(weapon, nomArme, true)) {
                trouve = 1;
                indexArme = listObjetArmes[index][0][0];
            }
            index++;
        }
        if (trouve) {
            new iditem = TrouverPlaceDansSac(client, indexArme);
            if (0 < iditem) {
                item = GetPlayerWeaponSlot(client, slot);
                if (RemovePlayerItem(client, item)) {
                    MettreObjetDansSac(client, iditem, indexArme);
                    PrintToChat(client, "%s %s a ‚t‚ rajout‚ dans ton sac !", "[Rp Magnetik : ->]", objetNom[indexArme][0][0]);
                }
            }
        }
    }
    return 0;
}

modelDeProp()
{
    new var1 = listPropmenus;
    listPropPrix[0] = 200;
    new var2 = listPropNom;
    strcopy(var2[0][0][var2], 60, "Un distributeur");
    listPropPrix[4] = 50;
    strcopy(listPropNom[4][0], 60, "Un canap‚");
    listPropPrix[8] = 100;
    strcopy(listPropNom[8][0], 60, "Une bibliothŠque");
    listPropPrix[12] = 35;
    strcopy(listPropNom[12][0], 60, "Une machine");
    listPropPrix[16] = 180;
    strcopy(listPropNom[16][0], 60, "Une gazini‚re");
    listPropPrix[20] = 150;
    strcopy(listPropNom[20][0], 60, "Une table … manger");
    listPropPrix[24] = 25;
    strcopy(listPropNom[24][0], 60, "Une chaise");
    listPropPrix[28] = 15;
    strcopy(listPropNom[28][0], 60, "Un pot de fleur");
    listPropPrix[32] = 125;
    strcopy(listPropNom[32][0], 60, "Une table en bois");
    listPropPrix[36] = 200;
    strcopy(listPropNom[36][0], 60, "Un grand placard");
    return 0;
}

spawnPropIkea(indexModel, Float:destinationProp[3])
{
    if (!IsModelPrecached(listPropmenus[indexModel][0][0])) {
        PrecacheModel(listPropmenus[indexModel][0][0], true);
    }
    new g_Propmenu = CreateEntityByName("prop_physics_override", -1);
    DispatchKeyValue(g_Propmenu, "model", listPropmenus[indexModel][0][0]);
    DispatchKeyValue(g_Propmenu, "solid", "6");
    DispatchKeyValue(g_Propmenu, "physdamagescale", "0.0");
    DispatchSpawn(g_Propmenu);
    TeleportEntity(g_Propmenu, destinationProp, NULL_VECTOR, NULL_VECTOR);
    return 0;
}

public bool:traceRayDontHitSelf(entity, mask, data)
{
    if (data == entity) {
        return false;
    }
    return true;
}

DecrocheTel(client, entity)
{
    if (entity == 1256) {
        if (ProcheJoueurPorte(1256, client)) {
            if (telOn1 == true) {
                telOn1 = 0;
                new valeur = GetRandomInt(0, 6);
                PrintToChat(client, "%s %s !", "[Rp Magnetik : ->]", EndroitDuBillet[valeur][0][0]);
                spawnPropArgent(1, PositionDuBillet[valeur][0][0]);
            }
            PrintToChat(client, "%s Bip Bip Bip ..... !", "[Rp Magnetik : ->]");
        }
    } else {
        if (entity == 1255) {
            if (ProcheJoueurPorte(1255, client)) {
                if (telOn2 == true) {
                    telOn2 = 0;
                    new valeur = GetRandomInt(0, 6);
                    PrintToChat(client, "%s %s !", "[Rp Magnetik : ->]", EndroitDuBillet[valeur][0][0]);
                    spawnPropArgent(1, PositionDuBillet[valeur][0][0]);
                }
                PrintToChat(client, "%s Bip Bip Bip ..... !", "[Rp Magnetik : ->]");
            }
        }
        if (entity == 1254) {
            if (ProcheJoueurPorte(1254, client)) {
                if (telOn3 == true) {
                    telOn3 = 0;
                    new valeur = GetRandomInt(0, 6);
                    PrintToChat(client, "%s %s !", "[Rp Magnetik : ->]", EndroitDuBillet[valeur][0][0]);
                    spawnPropArgent(1, PositionDuBillet[valeur][0][0]);
                }
                PrintToChat(client, "%s Bip Bip Bip ..... !", "[Rp Magnetik : ->]");
            }
        }
        if (entity == 1257) {
            if (ProcheJoueurPorte(1257, client)) {
                if (telOn4 == true) {
                    telOn4 = 0;
                    new valeur = GetRandomInt(0, 6);
                    PrintToChat(client, "%s %s !", "[Rp Magnetik : ->]", EndroitDuBillet[valeur][0][0]);
                    spawnPropArgent(1, PositionDuBillet[valeur][0][0]);
                }
                PrintToChat(client, "%s Bip Bip Bip ..... !", "[Rp Magnetik : ->]");
            }
        }
    }
    return 0;
}

CreationPlanqueBillet()
{
    new var1 = EndroitDuBillet;
    Format(var1[0][0][var1], 70, "L'argent est comme pr‚vu dans la poubelle devant le bar");
    new var2 = PositionDuBillet;
    var2[0][0][var2] = -1006390477;
    new var3 = PositionDuBillet;
    var3[0][0][var3][4] = -991226429;
    new var4 = PositionDuBillet;
    var4[0][0][var4][8] = -1012306739;
    Format(EndroitDuBillet[4][0], 70, "L'argent est comme pr‚vu dans la poubelle dans le parc de la paix");
    PositionDuBillet[4][0] = -980948357;

/* ERROR! unknown load */
 function "CreationPlanqueBillet" (number 329)
telechargerSon()
{
    AddFileToDownloadsTable("sound/frez/phone/vieux_tel.mp3");
    AddFileToDownloadsTable("sound/ambient/frez/vomi2.mp3");
    PrecacheSound("/frez/phone/vieux_tel.mp3", true);
    PrecacheSound("ambient/frez/vomi2.mp3", true);
    return 0;
}

spawnPropArgent(index, Float:destinationProp[3])
{
    if (index == 1) {
        if (!IsModelPrecached("models/props/cs_assault/money.mdl")) {
            PrecacheModel("models/props/cs_assault/money.mdl", true);
        }
        new g_Propmenu = CreateEntityByName("prop_physics_override", -1);
        DispatchKeyValue(g_Propmenu, "model", "models/props/cs_assault/money.mdl");
        DispatchKeyValue(g_Propmenu, "solid", "6");
        DispatchKeyValue(g_Propmenu, "physdamagescale", "0.0");
        DispatchSpawn(g_Propmenu);
        TeleportEntity(g_Propmenu, destinationProp, NULL_VECTOR, NULL_VECTOR);
    } else {
        if (index == 2) {
        }
    }
    return 0;
}

verifieSiArgent(client, entity)
{
    decl String:strModel[152];
    GetEntPropString(entity, PropType:1, "m_ModelName", strModel, 150);
    if (StrEqual(strModel, "models/props/cs_assault/money.mdl", true)) {
        RemoveEdict(entity);
        new valeur = GetRandomInt(10, 90);
        new var1 = clientCash[client];
        var1 = var1[0][0] + valeur;
        PrintToChat(client, "%s %d $ on ‚tait rajout‚ dans ton portefeuille !", "[Rp Magnetik : ->]", valeur);
    }
    return 0;
}

public Action:TimerPhone(Handle:timer)
{
    VerificationTelephone();
    return Action:0;
}

VerificationTelephone()
{
    if (telOn1 == true) {
        decl Float:vecOrigin[3];
        GetEntDataVector(1256, m_vecOrigin, vecOrigin);
        if (!IsSoundPrecached("/frez/phone/vieux_tel.mp3")) {
            PrecacheSound("/frez/phone/vieux_tel.mp3", true);
        }
        EmitSoundToAll("/frez/phone/vieux_tel.mp3", 1256, 0, 75, 0, 1, 100, -1, vecOrigin, NULL_VECTOR, true, 0);
    } else {
        if (telOn2 == true) {
            decl Float:vecOrigin[3];
            GetEntDataVector(1255, m_vecOrigin, vecOrigin);
            if (!IsSoundPrecached("/frez/phone/vieux_tel.mp3")) {
                PrecacheSound("/frez/phone/vieux_tel.mp3", true);
            }
            EmitSoundToAll("/frez/phone/vieux_tel.mp3", 1255, 0, 75, 0, 1, 100, -1, vecOrigin, NULL_VECTOR, true, 0);
        }
        if (telOn3 == true) {
            decl Float:vecOrigin[3];
            GetEntDataVector(1254, m_vecOrigin, vecOrigin);
            if (!IsSoundPrecached("/frez/phone/vieux_tel.mp3")) {
                PrecacheSound("/frez/phone/vieux_tel.mp3", true);
            }
            EmitSoundToAll("/frez/phone/vieux_tel.mp3", 1254, 0, 75, 0, 1, 100, -1, vecOrigin, NULL_VECTOR, true, 0);
        }
        if (telOn4 == true) {
            decl Float:vecOrigin[3];
            GetEntDataVector(1257, m_vecOrigin, vecOrigin);
            if (!IsSoundPrecached("/frez/phone/vieux_tel.mp3")) {
                PrecacheSound("/frez/phone/vieux_tel.mp3", true);
            }
            EmitSoundToAll("/frez/phone/vieux_tel.mp3", 1257, 0, 75, 0, 1, 100, -1, vecOrigin, NULL_VECTOR, true, 0);
        }
    }
    return 0;
}

AllumeUnTelAuAzar()
{
    new valeur = GetRandomInt(1, 4);
    if (valeur == 1) {
        telOn1 = 1;
    } else {
        if (valeur == 2) {
            telOn2 = 1;
        }
        if (valeur == 3) {
            telOn3 = 1;
        }
        if (valeur == 4) {
            telOn4 = 1;
        }
    }
    return 0;
}

DeclancherTelephone()
{
    if (minute == 60) {
        AllumeUnTelAuAzar();
    } else {
        if (minute == 180) {
            AllumeUnTelAuAzar();
        }
        if (minute == 420) {
            AllumeUnTelAuAzar();
        }
        if (minute == 720) {
            AllumeUnTelAuAzar();
        }
        if (minute == 900) {
            AllumeUnTelAuAzar();
        }
        if (minute == 1260) {
            AllumeUnTelAuAzar();
        }
        if (minute == 1380) {
            AllumeUnTelAuAzar();
        }
    }
    return 0;
}

AfficheMenuEvent(client)
{
    if (inListAdmin(client)) {
        new Handle:g_MenuEvent = CreateMenu(MenuHandler:55, MenuAction:28);
        SetMenuTitle(g_MenuEvent, "| Menu Des events |");
        AddMenuItem(g_MenuEvent, "1", "Spawn des Billets $", 0);
        AddMenuItem(g_MenuEvent, "2", "Declancher Guerre de Gangs", 0);
        DisplayMenu(g_MenuEvent, client, 300);
    }
    return 0;
}

public BlockMenuDesEvents(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    decl String:parametre[8];
    GetMenuItem(menu, choice, parametre, 8, 0, "", 0);
    new num = StringToInt(parametre, 10);
    if (num == 1) {
        decl Float:eyesOrigin[3];
        decl Float:eyesAngles[3];
        GetClientEyePosition(client, eyesOrigin);
        GetClientEyeAngles(client, eyesAngles);
        decl Float:destinationProp[3];
        new Handle:trace = TR_TraceRayFilterEx(eyesOrigin, eyesAngles, 33570827, RayType:1, TraceEntityFilter:289, client);
        TR_GetEndPosition(destinationProp, trace);
        CloseHandle(trace);
        spawnPropArgent(1, destinationProp);
        AfficheMenuEvent(client);
    } else {
        if (num == 2) {
            declancheEvent();
        }
    }
    return 0;
}

InitialiseEventGuerre()
{
    initialiseInscription();
    initialiseZoneDeTp();
    return 0;
}

initialiseZoneDeTp()
{
    zoneTpEventG[4][0] = 1125126636;

/* ERROR! unknown load */
 function "initialiseZoneDeTp" (number 340)
initialiseInscription()
{
    new i = 1;
    while (i < 21) {
        NumeroClient[i] = 0;
        JoueurVivant[i] = 0;
        i++;
    }
    return 0;
}

InscriptionALevent(client)
{
    if (ProcheJoueurPorte(1322, client)) {
        if (InscriptionOn) {
            if (JoeurInscripEventG(client)) {
                new Handle:g_MenuStopEvent = CreateMenu(MenuHandler:107, MenuAction:28);
                SetMenuTitle(g_MenuStopEvent, "| Vous etes d‚ja Inscrit | \n souhaitez-vous vous d‚sinscrire ?");
                AddMenuItem(g_MenuStopEvent, "1", "-> D‚sinscrire", 0);
                AddMenuItem(g_MenuStopEvent, "2", "-> Annuler", 0);
                DisplayMenu(g_MenuStopEvent, client, 300);
            } else {
                if (TouteLesPlacesSonPris()) {
                    PrintToChat(client, "%s Il n'y as plus de place pour l'event !", "[Rp Magnetik : ->]");
                }
                new Handle:g_MenuSInscrire = CreateMenu(MenuHandler:41, MenuAction:28);
                SetMenuTitle(g_MenuSInscrire, "| Inscription Event Guerre de Gang (100$) |");
                AddMenuItem(g_MenuSInscrire, "1", "-> Accepter", 0);
                AddMenuItem(g_MenuSInscrire, "2", "-> Refuser", 0);
                DisplayMenu(g_MenuSInscrire, client, 300);
            }
        }
        PrintToChat(client, "%s Il n'y as pas d'event pour le moment !", "[Rp Magnetik : ->]");
    }
    return 0;
}

desinscireDeLevent(client)
{
    decl String:nameTarget[32];
    GetClientName(client, nameTarget, 32);
    new i = 1;
    while (i < 21) {
        if (client == NumeroClient[i][0][0]) {
            NumeroClient[i] = 0;
            JoueurVivant[i] = 0;
            PrintToChat(client, "%s Vous ‚tŠs d‚sinscrit de l'event !", "[Rp Magnetik : ->]");
            PrintToChatAll("%s [Event Auto] %s c'est d‚sinscrit de l'event (Guerre de Gang) !", 250152, nameTarget);
            return 0;
        }
        i++;
    }
    return 0;
}

InscrireJoueurAlevent(client)
{
    if (InscriptionOn) {
        new place = 2;
        decl String:nameTarget[32];
        GetClientName(client, nameTarget, 32);
        new compte = verifieAsseArgent(client, 100);
        if (compte) {
            new nbVert = 0;
            new nbRose = 0;
            new i = 1;
            while (i < 21) {
                if (i < 11) {
                    if (NumeroClient[i][0][0]) {
                        nbVert++;
                        i++;
                    }
                    i++;
                } else {
                    if (NumeroClient[i][0][0]) {
                        nbRose++;
                        i++;
                    }
                    i++;
                }
                i++;
            }
            if (nbRose + nbVert < 20) {
                if (nbVert <= nbRose) {
                    new j = 1;
                    while (j < 11) {
                        if (NumeroClient[j][0][0]) {
                            j++;
                        } else {
                            NumeroClient[j] = client;
                            JoueurVivant[j] = 1;
                            place = 1;
                            PrintToChat(client, "%s Vous ‚tŠs inscrit … l'event dans l'‚quipe VERT, veuillez patienter avant le d‚but de l'event !", "[Rp Magnetik : ->]");
                            PrintToChatAll("%s [Event Auto] %s c'est inscrit dans la TEAM VERT (%d place restant)", 250376, nameTarget, 10 - nbVert + 1);
                            if (compte == 1) {
                                new var1 = clientCash[client];
                                var1 = var1[0][0] + -100;
                            } else {
                                if (compte == 2) {
                                    new var2 = clientBank[client];
                                    var2 = var2[0][0] + -100;
                                }
                            }
                        }
                        j++;
                    }
                } else {
                    new k = 11;
                    while (k < 21) {
                        if (NumeroClient[k][0][0]) {
                            k++;
                        } else {
                            NumeroClient[k] = client;
                            JoueurVivant[k] = 1;
                            place = 1;
                            PrintToChat(client, "%s Vous ‚tŠs inscrit … l'event dans l'‚quipe ROSE, veuillez patienter avant le d‚but de l'event !", "[Rp Magnetik : ->]");
                            PrintToChatAll("%s [Event Auto] %s c'est inscrit dans la TEAM ROSE (%d place restant)", 250600, nameTarget, 10 - nbRose + 1);
                            if (compte == 1) {
                                new var3 = clientCash[client];
                                var3 = var3[0][0] + -100;
                            } else {
                                if (compte == 2) {
                                    new var4 = clientBank[client];
                                    var4 = var4[0][0] + -100;
                                }
                            }
                        }
                        k++;
                    }
                }
            } else {
                PrintToChat(client, "%s Il n'y as plus de place pour vous inscrire a l'event !", "[Rp Magnetik : ->]");
            }
            if (place == 2) {
                PrintToChat(client, "%s Il n'y as plus de place pour vous inscrire a l'event !", "[Rp Magnetik : ->]");
            }
        } else {
            PrintToChat(client, "%s Vous n'avez pas assez d'argent !", "[Rp Magnetik : ->]");
        }
    } else {
        PrintToChat(client, "%s Il n'y as pas d'event pour le moment !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockInscriptionEvent(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    if (InscriptionOn) {
        decl String:parametre[4];
        GetMenuItem(menu, choice, parametre, 3, 0, "", 0);
        new choix = StringToInt(parametre, 10);
        if (choix == 1) {
            InscrireJoueurAlevent(client);
        }
    } else {
        PrintToChat(client, "%s Il n'y as pas d'event pour le moment !", "[Rp Magnetik : ->]");
    }
    return 0;
}

public BlockStopInscription(Handle:menu, MenuAction:action, client, choice)
{
    if (action != MenuAction:4) {
        return 0;
    }
    if (InscriptionOn) {
        decl String:parametre[4];
        GetMenuItem(menu, choice, parametre, 3, 0, "", 0);
        new choix = StringToInt(parametre, 10);
        if (JoeurInscripEventG(client)) {
            if (choix == 1) {
                desinscireDeLevent(client);
            }
        }
    } else {
        PrintToChat(client, "%s Il n'y as pas d'event pour le moment !", "[Rp Magnetik : ->]");
    }
    return 0;
}

JoeurInscripEventG(client)
{
    new i = 1;
    while (i < 21) {
        if (client == NumeroClient[i][0][0]) {
            return 1;
        }
        i++;
    }
    return 0;
}

TouteLesPlacesSonPris()
{
    new j = 0;
    new i = 1;
    while (i < 21) {
        if (NumeroClient[i][0][0]) {
            j++;
            i++;
        }
        i++;
    }
    if (j == 20) {
        return 1;
    }
    return 0;
}

VerificationJoueurEvent()
{
    if (EventGuerre) {
        new i = 1;
        while (i < 21) {
            if (NumeroClient[i][0][0]) {
                new var1;
                if (IsClientInGame(NumeroClient[i][0][0])) {
                    if (i < 11) {
                        if (JoueurVivant[i][0][0] == 1) {
                            SetEntityRenderColor(NumeroClient[i][0][0], 6, 255, 0, 255);
                            i++;
                        } else {
                            SetEntityRenderColor(NumeroClient[i][0][0], 255, 255, 255, 255);
                            i++;
                        }
                        i++;
                    }
                    if (JoueurVivant[i][0][0] == 1) {
                        SetEntityRenderColor(NumeroClient[i][0][0], 255, 0, 234, 255);
                        i++;
                    }
                    SetEntityRenderColor(NumeroClient[i][0][0], 255, 255, 255, 255);
                    i++;
                }
                i++;
            }
            i++;
        }
    }
    return 0;
}

MettreCoLorInitial()
{
    new i = 1;
    while (i < 21) {
        if (NumeroClient[i][0][0]) {
            new var1;
            if (IsClientInGame(NumeroClient[i][0][0])) {
                SetEntityRenderColor(NumeroClient[i][0][0], 255, 255, 255, 255);
                i++;
            }
            i++;
        }
        i++;
    }
    return 0;
}

TeleporterLesJou()
{
    new i = 1;
    while (i < 21) {
        if (NumeroClient[i][0][0]) {
            new var1;
            if (IsClientInGame(NumeroClient[i][0][0])) {
                TeleportEntity(NumeroClient[i][0][0], zoneTpEventG[i][0][0], NULL_VECTOR, NULL_VECTOR);
                SetEntityHealth(NumeroClient[i][0][0], 100);
                if (i < 11) {
                    PrintToChat(NumeroClient[i][0][0], "%s  EvEnT : TUER LE GANG de Couleur ROSE POUR GAGNER ! (Vous Avez 15minutes !)", "[Rp Magnetik : ->]");
                    i++;
                }
                PrintToChat(NumeroClient[i][0][0], "%s  EvEnT : TUER LE GANG de Couleur VERT POUR GAGNER ! (Vous Avez 15minutes !)", "[Rp Magnetik : ->]");
                i++;
            }
            i++;
        }
        i++;
    }
    return 0;
}

PlusDeDeuxPlacePrise()
{
    new nb = 0;
    new i = 1;
    while (i < 21) {
        if (NumeroClient[i][0][0]) {
            nb++;
            i++;
        }
        i++;
    }
    return nb > 1;
}

declancheEvent()
{
    new var1;
    if (EventGuerre) {
        secondeEvent = 0;
        PrintToChatAll("%s  EvEnT AuTo : Les Inscriptions Pour l'event (La GUERRE DE GANGS) est ouvertes !", 251352);
        InscriptionOn = 1;
    } else {
        PrintToChatAll("%s  EvEnT AuTo : L'event n'est pas terminer !", 251424);
    }
    return 0;
}

VerifTimePourEvent()
{
    new var1;
    if (minute == 600) {
        PrintToChatAll("%s  EvEnT AuTo : Les Inscriptions Pour l'event (La GUERRE DE GANGS) sera ouvert a 12h00 au NPC principal !", 251556);
    }
    if (minute == 720) {
        declancheEvent();
    }
    if (InscriptionOn) {
        secondeEvent += 1;
        if (secondeEvent > 180) {
            PrintToChatAll("%s  EvEnT AuTo : Les Inscriptions Pour l'event (La GUERRE DE GANGS) Sont Termin‚s !", 251668);
            InscriptionOn = 0;
            if (!PlusDeDeuxPlacePrise()) {
                PrintToChatAll("%s  EvEnT AuTo : (La GUERRE DES GANGS) est Annul‚ car moins de 2 personnes sont inscrites !", 251788);
                donnerArgentEnMatchNull();
                EventGuerre = 0;
                InscriptionOn = 0;
                MettreCoLorInitial();
                initialiseInscription();
                secondeEvent = 0;
            }
            PrintToChatAll("%s  EvEnT AuTo : La GUERRE DES GANGS PEU COMMENCER !", 251868);
            TeleporterLesJou();
            EventGuerre = 1;
            secondeEvent = 0;
        }
    }
    if (EventGuerre) {
        verifieSiGagnant();
        secondeEvent += 1;
    }
    return 0;
}

verifieSiGagnant()
{
    if (secondeEvent > 899) {
        PrintToChatAll("%s  EvEnT AuTo (La GUERRE DES GANGS): Event Terminer (Match Null) !", 251964);
        donnerArgentEnMatchNull();
        EventGuerre = 0;
        InscriptionOn = 0;
        MettreCoLorInitial();
        initialiseInscription();
        secondeEvent = 0;
    } else {
        new tmR = 0;
        new tmV = 0;
        new i = 1;
        while (i < 21) {
            if (i < 11) {
                if (JoueurVivant[i][0][0]) {
                    tmV++;
                    i++;
                }
                i++;
            } else {
                if (JoueurVivant[i][0][0]) {
                    tmR++;
                    i++;
                }
                i++;
            }
            i++;
        }
        new var1;
        if (tmR) {
            PrintToChatAll("%s  EvEnT AuTo (La GUERRE DES GANGS): Event Terminer (Match Null) !", 252060);
            donnerArgentEnMatchNull();
            EventGuerre = 0;
            InscriptionOn = 0;
            MettreCoLorInitial();
            initialiseInscription();
            secondeEvent = 0;
        } else {
            new var2;
            if (tmR) {
                PrintToChatAll("%s  EvEnT AuTo (La GUERRE DES GANGS): Event Terminer (Le Gang Vert … gagner) !", 252168);
                DonnerArgentEquipe(1);
                EventGuerre = 0;
                InscriptionOn = 0;
                MettreCoLorInitial();
                initialiseInscription();
                secondeEvent = 0;
            }
            new var3;
            if (tmR) {
                PrintToChatAll("%s  EvEnT AuTo (La GUERRE DES GANGS): Event Terminer (Le Gang Rose … gagner) !", 252276);
                DonnerArgentEquipe(2);
                EventGuerre = 0;
                InscriptionOn = 0;
                MettreCoLorInitial();
                initialiseInscription();
                secondeEvent = 0;
            }
        }
    }
    return 0;
}

DonnerArgentEquipe(team)
{
    if (team == 1) {
        new i = 1;
        while (i < 11) {
            new var1;
            if (NumeroClient[i][0][0]) {
                new var3 = clientCash[NumeroClient[i][0][0]];
                var3 = var3[0][0] + 200;
                i++;
            }
            i++;
        }
    } else {
        if (team == 2) {
            new i = 11;
            while (i < 21) {
                new var2;
                if (NumeroClient[i][0][0]) {
                    new var4 = clientCash[NumeroClient[i][0][0]];
                    var4 = var4[0][0] + 200;
                    i++;
                }
                i++;
            }
        }
    }
    return 0;
}

donnerArgentEnMatchNull()
{
    new i = 1;
    while (i < 21) {
        if (NumeroClient[i][0][0]) {
            new var1;
            if (IsClientInGame(NumeroClient[i][0][0])) {
                new var2 = clientCash[NumeroClient[i][0][0]];
                var2 = var2[0][0] + 100;
                i++;
            }
            i++;
        }
        i++;
    }
    return 0;
}

public Action:EventGDGDeath(Handle:event, String:name[], bool:dontBroadcast)
{
    if (EventGuerre) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new attack = 0;
        if (GetEventInt(event, "attacker")) {
            attack = GetClientOfUserId(GetEventInt(event, "attacker"));
        }
        new var1;
        if (attack) {
            new bool:atEvent = 0;
            new bool:clEvent = 0;
            new indice = 0;
            new i = 1;
            while (i < 21) {
                if (client == NumeroClient[i][0][0]) {
                    clEvent = 1;
                    indice = i;
                }
                if (attack == NumeroClient[i][0][0]) {
                    atEvent = 1;
                    i++;
                }
                i++;
            }
            new var2;
            if (atEvent) {
                JoueurVivant[indice] = 0;
                PrintToChat(client, "%s  EvEnT Auto : Vous ‚tes ‚limin‚ de l'event (La Guerre Des gangs) !", "[Rp Magnetik : ->]");
                EnvoieMessageUnMort(indice);
            }
        }
    }
    return Action:0;
}

EnvoieMessageUnMort(indice)
{
    new nbVert = 0;
    new nbRose = 0;
    new i = 1;
    while (i < 21) {
        if (i < 11) {
            if (JoueurVivant[i][0][0] == 1) {
                nbVert++;
                i++;
            }
            i++;
        } else {
            if (JoueurVivant[i][0][0] == 1) {
                nbRose++;
                i++;
            }
            i++;
        }
        i++;
    }
    new var1;
    if (nbVert > 0) {
        if (NumeroClient[indice][0][0]) {
            decl String:name[32];
            GetClientName(NumeroClient[indice][0][0], name, 32);
            new i = 1;
            while (i < 21) {
                if (indice < 11) {
                    if (NumeroClient[i][0][0]) {
                        PrintToChat(NumeroClient[i][0][0], "%s  [EvEnT] %s de l'‚quipe VERT est Mort, plus que %d personnes … ‚limin‚es !", "[Rp Magnetik : ->]", name, nbVert);
                        i++;
                    }
                    i++;
                } else {
                    if (NumeroClient[i][0][0]) {
                        PrintToChat(NumeroClient[i][0][0], "%s  [EvEnT] %s de l'‚quipe ROSE est Mort, plus que %d personnes … ‚limin‚es !", "[Rp Magnetik : ->]", name, nbRose);
                        i++;
                    }
                    i++;
                }
                i++;
            }
        }
    }
    return 0;
}

JoueurInscritEventTeam(client)
{
    new i = 1;
    while (i < 21) {
        if (i < 11) {
            if (client == NumeroClient[i][0][0]) {
                if (JoueurVivant[i][0][0] == 1) {
                    return 1;
                }
                i++;
            }
            i++;
        } else {
            if (client == NumeroClient[i][0][0]) {
                if (JoueurVivant[i][0][0] == 1) {
                    return 2;
                }
                i++;
            }
            i++;
        }
        i++;
    }
    return 0;
}

public Action:Event_PlayerSpawnGDG(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new i = 1;
    while (i < 11) {
        if (client == NumeroClient[i][0][0]) {
            if (InscriptionOn) {
                return Action:0;
            } else {
                if (JoueurVivant[i][0][0] == 1) {
                    TeleportEntity(client, zoneTpEventG[i][0][0], NULL_VECTOR, NULL_VECTOR);
                    return Action:0;
                }
                return Action:0;
            }
            return Action:0;
        }
        i++;
    }
    return Action:0;
}

public Action:DamagePourEventGDG(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if (EventGuerre) {
        new var1;
        if (victim > 0) {
            new var2;
            if (IsClientInGame(victim)) {
                new numV = JoueurInscritEventTeam(victim);
                new numA = JoueurInscritEventTeam(attacker);
                new var3;
                if (numV) {
                    damage = 0;
                    return Action:1;
                }
            }
        }
    }
    return Action:0;
}

stopInscriptionEventGdG(client)
{
    decl String:nameTarget[32];
    GetClientName(client, nameTarget, 32);
    new i = 1;
    while (i < 21) {
        if (client == NumeroClient[i][0][0]) {
            NumeroClient[i] = 0;
            JoueurVivant[i] = 0;
            PrintToChatAll("%s [Event Auto] %s c'est d‚sinscrit de l'event (Guerre de Gang) !", 252724, nameTarget);
            return 0;
        }
        i++;
    }
    return 0;
}

VerificationPlayerEmpoissone()
{
    if (seconde == 30) {
        ActiveMaladi();
    }
    return 0;
}

ActiveMaladi()
{
    new client = 1;
    while (client <= MaxClients) {
        new var1;
        if (IsClientInGame(client)) {
            if (clientEmpoissone[client][0][0]) {
                ActivationPoison(client);
                client++;
            }
            client++;
        }
        client++;
    }
    return 0;
}

ActivationPoison(client)
{
    if (!IsSoundPrecached("ambient/frez/vomi2.mp3")) {
        PrecacheSound("ambient/frez/vomi2.mp3", true);
    }
    decl Float:eyeposition[3];
    GetClientEyePosition(client, eyeposition);
    EmitSoundToClient(client, "ambient/frez/vomi2.mp3", client, 0, 75, 0, 1, 100, -1, eyeposition, NULL_VECTOR, true, 0);
    if (!IsModelPrecached("sprites/smoke.vmt")) {
        smokesprite = PrecacheModel("sprites/smoke.vmt", false);
    }
    TE_SetupSmoke(eyeposition, smokesprite, 5, 5);
    TE_SendToAll(0);
    PrintToChat(client, "%s Vous ˆtes empoisonn‚ ! Il faut trouver un antidote pour gu‚rir !", "[Rp Magnetik : ->]");
    CreateTimer(3, tacheVert, client, 0);
    CreateTimer(6, tacheVert, client, 0);
    CreateTimer(9, tacheVert, client, 0);
    CreateTimer(12, tacheVert, client, 0);
    CreateTimer(15, tacheVert, client, 0);
    CreateTimer(18, tacheVert, client, 0);
    SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", 0.6);
    CreateTimer(5, EnleverHp, client, 0);
    CreateTimer(10, EnleverHp, client, 0);
    CreateTimer(15, EnleverHp, client, 0);
    CreateTimer(19, EnleverHp, client, 0);
    CreateTimer(3, tourneLatete, client, 0);
    CreateTimer(6, tourneLatete, client, 0);
    CreateTimer(9, tourneLatete, client, 0);
    CreateTimer(12, tourneLatete, client, 0);
    CreateTimer(15, tourneLatete, client, 0);
    CreateTimer(18, tourneLatete, client, 0);
    CreateTimer(20, StopEffetAll, client, 0);
    return 0;
}


/* ERROR! unknown operator */
 function "tacheVert" (number 367)

/* ERROR! unknown operator */
 function "tourneLatete" (number 368)
public Action:EnleverHp(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        new hp = GetClientHealth(client);
        if (hp == 1) {
            SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", 1);
            ForcePlayerSuicide(client);
        } else {
            SetEntityHealth(client, hp + -1);
            SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", 0.6);
        }
    }
    return Action:0;
}

public Action:StopEffetAll(Handle:timer, client)
{
    new var1;
    if (IsClientInGame(client)) {
        SetEntPropFloat(client, PropType:1, "m_flLaggedMovementValue", 1);
    }
    return Action:0;
}


/* ERROR! unknown operator */
 function "ActivePoisson" (number 371)
bool:ActiveAntidote(client)
{
    if (clientEmpoissone[client][0][0]) {
        clientEmpoissone[client] = 0;
        PrintToChat(client, "%s Vous ˆtes gu‚ri !", "[Rp Magnetik : ->]");
        return true;
    }
    PrintToChat(client, "%s Vous n'ˆtes pas malade !", "[Rp Magnetik : ->]");
    return false;
}

prepatchsounds()
{
    new soundspecification:i = 0;
    while (i < soundspecification:7) {
        PrecacheSound(sounddata[i][0][0], true);
        i++;
    }
    return 0;
}

playsound(entity, soundtype:soundtypetoplay, Float:soundposition[3])
{
    if (!soundenabled()) {
        return 0;
    }
    if (soundtypetoplay) {
        if (soundtypetoplay == soundtype:1) {
            EmitSoundToClient(entity, sounddata[4][0], entity, 0, 75, 0, 1, 100, -1, soundposition, NULL_VECTOR, true, 0);
        }
        if (soundtypetoplay == soundtype:2) {
            EmitSoundToClient(entity, sounddata[GetRandomInt(3, 6)][0][0], entity, 0, 75, 0, 1, 100, -1, soundposition, NULL_VECTOR, true, 0);
        }
    } else {
        new var1 = sounddata;
        EmitSoundToClient(entity, var1[0][0][var1], entity, 0, 75, 0, 1, 100, -1, soundposition, NULL_VECTOR, true, 0);
    }
    return 0;
}

playsoundfromclient(client, soundtype:soundtypetoplay)
{
    decl Float:eyeposition[3];
    GetClientEyePosition(client, eyeposition);
    playsound(client, soundtypetoplay, eyeposition);
    return 0;
}

creategravityguncvar()
{
    CreateConVar("gravitygunmod_version", "1.0", "plugin info cvar", 8448, false, 0, false, 0);
    cvar_maxpickupdistance = CreateConVar("gravitygunmod_maxpickupdistance", "200", "max distance to allow grab", 0, false, 0, false, 0);
    cvar_grabforcemultiply = CreateConVar("gravitygunmod_grabforcemultiply", "10", "multiply grab force by this value", 0, false, 0, false, 0);
    cvar_grab_delay = CreateConVar("gravitygunmod_grab_delay", "0.2", "grab delay", 0, false, 0, false, 0);
    cvar_grab_defaultdistance = CreateConVar("gravitygunmod_grab_defaultdistance", "100.0", "grab distance for default", 0, false, 0, false, 0);
    cvar_strictmousecontrol = CreateConVar("gravitygunmod_strictmousecontrol", "0", "force players to hold speed button to use mouse button for gravity gun function", 0, false, 0, false, 0);
    cvar_enablesound = CreateConVar("gravitygunmod_enablesound", "1", "1 for enable 0 for disable", 0, false, 0, false, 0);
    cvar_blueteam_enable = CreateConVar("gravitygunmod_blueteam_enable", "1", "1 for enable 0 for disable", 0, false, 0, false, 0);
    cvar_redteam_enable = CreateConVar("gravitygunmod_redteam_enable", "0", "1 for enable 0 for disable", 0, false, 0, false, 0);
    AutoExecConfig(true, "", "sourcemod");
    return 0;
}

bool:teamcanusegravitygun(teamnum)
{
    new var1;
    if (teamnum == 3) {
        return true;
    }
    new var2;
    if (teamnum == 2) {
        return true;
    }
    return false;
}

bool:soundenabled()
{
    return GetConVarBool(cvar_enablesound);
}

public PreThinkHook(client)
{
    new var1;
    if (IsClientConnectedIngameAlive(client)) {
        new buttons = GetClientButtons(client);
        new clientteam = GetClientTeam(client);
        if (grabbedentref[client][0][0] == -1) {
            new var2;
            if (buttons & 32) {
                if (teamcanusegravitygun(clientteam)) {
                    grab(client);
                }
            }
        } else {
            if (EntRefToEntIndex(grabbedentref[client][0][0]) == -1) {
                grabbedentref[client] = -1;
                playsoundfromclient(client, soundtype:0);
            }
            new var3;
            if (buttons & 32) {
                release(client);
            }
            hold(client);
        }
        if (!buttons & 32) {
            keybuffer[client] = keybuffer[client][0][0] & -33;
        }
    } else {
        release(client);
    }
    return 0;
}

grab(client)
{
    new targetentity = 0;
    new Float:distancetoentity = 0;
    decl Float:resultpos[3];
    targetentity = GetClientAimEntity3(client, distancetoentity, resultpos);
    new var1;
    if (targetentity != -1) {
        if (distancetoentity <= GetConVarFloat(cvar_maxpickupdistance)) {
            if (!clientcangrab(client)) {
                return 0;
            }
            SetEntPropEnt(targetentity, PropType:0, "m_hOwnerEntity", client);
            grabbedentref[client] = EntIndexToEntRef(targetentity);
            decl Float:clienteyeangle[3];
            decl Float:entityangle[3];
            GetEntPropVector(grabbedentref[client][0][0], PropType:0, "m_angRotation", entityangle);
            GetClientEyeAngles(client, clienteyeangle);
            playeranglerotate[client][0][0][0] = 0;
            playeranglerotate[client][0][0][4] = 0;
            playeranglerotate[client][0][0][8] = 0;
            grabangle[client][0][0][0] = 0;
            grabangle[client][0][0][4] = 0;
            grabangle[client][0][0][8] = 0;
            grabdistance[client] = GetConVarFloat(cvar_grab_defaultdistance);
            decl matrix[12];
            matrix3x4FromAnglesNoOrigin(clienteyeangle, matrix);
            decl Float:temp[3];
            MatrixAngles(matrix, temp);
            TransformAnglesToLocalSpace(entityangle, grabangle[client][0][0], matrix);
            keybuffer[client] = keybuffer[client][0][0] | 2048;
            playsoundfromclient(client, soundtype:1);
        }
    } else {
        if (targetentity != -1) {
            new sonidmetier = clientIdMetier[client][0][0];
            new var2;
            if (sonidmetier == 2) {
                decl String:classname[64];
                GetEdictClassname(targetentity, classname, 64);
                if (StrContains(classname, "player", false) != -1) {
                    if (distancetoentity <= GetConVarFloat(cvar_maxpickupdistance)) {
                        if (!clientcangrab(client)) {
                            return 0;
                        }
                        SetEntPropEnt(targetentity, PropType:0, "m_hOwnerEntity", client);
                        grabbedentref[client] = EntIndexToEntRef(targetentity);
                        decl Float:clienteyeangle[3];
                        decl Float:entityangle[3];
                        GetEntPropVector(grabbedentref[client][0][0], PropType:0, "m_angRotation", entityangle);
                        GetClientEyeAngles(client, clienteyeangle);
                        playeranglerotate[client][0][0][0] = 0;
                        playeranglerotate[client][0][0][4] = 0;
                        playeranglerotate[client][0][0][8] = 0;
                        grabangle[client][0][0][0] = 0;
                        grabangle[client][0][0][4] = 0;
                        grabangle[client][0][0][8] = 0;
                        grabdistance[client] = GetConVarFloat(cvar_grab_defaultdistance);
                        decl matrix[12];
                        matrix3x4FromAnglesNoOrigin(clienteyeangle, matrix);
                        decl Float:temp[3];
                        MatrixAngles(matrix, temp);
                        TransformAnglesToLocalSpace(entityangle, grabangle[client][0][0], matrix);
                        keybuffer[client] = keybuffer[client][0][0] | 2048;
                        playsoundfromclient(client, soundtype:1);
                    }
                }
            }
        }
    }
    return 0;
}

release(client)
{
    if (!clientcangrab(client)) {
        return 0;
    }
    if (grabbedentref[client][0][0] != -1) {
        if (IsValidEdict(grabbedentref[client][0][0])) {
            decl String:classname[64];
            if (GetEdictClassname(grabbedentref[client][0][0], classname, 64)) {
                if (StrEqual(classname, "player", true)) {
                    SetEntProp(grabbedentref[client][0][0], PropType:0, "movetype", any:2, 1);
                    SetEntPropFloat(grabbedentref[client][0][0], PropType:1, "m_flLaggedMovementValue", 1);
                }
            }
        }
    }
    new var1;
    if (grabbedentref[client][0][0] != -1) {
        SetEntPropEnt(grabbedentref[client][0][0], PropType:0, "m_hOwnerEntity", -1);
        if (IsClientConnectedIngame(client)) {
            playsoundfromclient(client, soundtype:0);
        }
    }
    grabbedentref[client] = -1;
    keybuffer[client] = keybuffer[client][0][0] | 2048;
    return 0;
}

hold(client)
{
    decl Float:resultpos[3];
    GetClientAimPosition(client, grabdistance[client][0][0], resultpos, TraceEntityFilter:299, client);
    decl Float:entityposition[3];
    decl Float:clientposition[3];
    decl Float:vector[3];
    GetEntPropVector(grabbedentref[client][0][0], PropType:0, "m_vecOrigin", entityposition);
    GetClientEyePosition(client, clientposition);
    decl Float:clienteyeangle[3];
    GetClientEyeAngles(client, clienteyeangle);
    decl Float:clienteyeangleafterchange[3];
    clienteyeangleafterchange[0] = FloatAdd(clienteyeangle[0], playeranglerotate[client][0][0][0]);
    clienteyeangleafterchange[4] = FloatAdd(clienteyeangle[4], playeranglerotate[client][0][0][4]);
    clienteyeangleafterchange[8] = FloatAdd(clienteyeangle[8], playeranglerotate[client][0][0][8]);
    decl playerlocalspace[12];
    decl playerlocalspaceafterchange[12];
    matrix3x4FromAnglesNoOrigin(clienteyeangle, playerlocalspace);
    matrix3x4FromAnglesNoOrigin(clienteyeangleafterchange, playerlocalspaceafterchange);
    decl Float:resultangle[3];
    TransformAnglesToWorldSpace(grabangle[client][0][0], resultangle, playerlocalspaceafterchange);
    TransformAnglesToLocalSpace(resultangle, grabangle[client][0][0], playerlocalspace);
    ZeroVector(playeranglerotate[client][0][0]);
    MakeVectorFromPoints(entityposition, resultpos, vector);
    ScaleVector(vector, GetConVarFloat(cvar_grabforcemultiply));
    decl Float:entityangle[3];
    decl Float:angvelocity[3];
    GetEntPropVector(grabbedentref[client][0][0], PropType:0, "m_angRotation", entityangle);
    angvelocity[0] = FloatSub(resultangle[0], entityangle[0]);
    angvelocity[4] = FloatSub(resultangle[4], entityangle[4]);
    angvelocity[8] = FloatSub(resultangle[8], entityangle[8]);
    ZeroVector(angvelocity);
    decl String:classname[64];
    GetEdictClassname(grabbedentref[client][0][0], classname, 64);
    if (StrEqual(classname, "player", true)) {
        TeleportEntity(grabbedentref[client][0][0], resultpos, NULL_VECTOR, NULL_VECTOR);
        SetEntProp(grabbedentref[client][0][0], PropType:0, "movetype", any:8, 1);
        SetEntPropFloat(grabbedentref[client][0][0], PropType:1, "m_flLaggedMovementValue", 0);
    } else {
        Phys_SetVelocity(EntRefToEntIndex(grabbedentref[client][0][0]), vector, angvelocity, true);
    }
    return 0;
}

bool:isgrabbableentity(entity)
{
    if (IsValidEdict(entity)) {
        decl String:classname[64];
        GetEdictClassname(entity, classname, 64);
        new var1;
        if (StrContains(classname, "prop_physics", false) == -1) {
            return true;
        }
    }
    return false;
}

bool:clientcangrab(client)
{
    new Float:now = GetGameTime();
    if (nextactivetime[client][0][0] <= now) {
        nextactivetime[client] = FloatAdd(now, GetConVarFloat(cvar_grab_delay));
        return true;
    }
    return false;
}

CS_SetClientClanTag(client, String:tag[])
{
    static Handle:settag;
    if (!settag) {
        new Handle:conf = LoadGameConfigFile("cssclantags");
        if (conf) {
            StartPrepSDKCall(SDKCallType:2);
            if (!PrepSDKCall_SetFromConf(conf, SDKFuncConfSource:1, "SetClanTag")) {
                CloseHandle(conf);
                ThrowError("SetClanTag not found");
            }
            PrepSDKCall_AddParameter(SDKType:7, SDKPassMethod:1, 0, 0);
            settag = EndPrepSDKCall();
            CloseHandle(conf);
            if (settag) {
            } else {
                ThrowError("Failed to create SetClanTag sdkcall");
            }
        }
        CloseHandle(conf);
        ThrowError("Cannot find gamedata/cssclantag.txt");
        return 0;
    }
    SDKCall(settag, client, tag);
    return 0;
}

public OnPluginStart()
{
    decl String:error[256];
    if (SQL_CheckConfig("roleplay_frez")) {
        db = SQL_Connect("roleplay_frez", true, error, 255);
        if (db) {
            decl String:driver[16];
            SQL_ReadDriver(db, driver, 16);
            if (StrEqual(driver, "mysql", false)) {
                SQL_FastQuery(db, "SET NAMES 'utf8'", -1);
            }
        }
        Log("Roleplay FReZ", "Impossible de se connecter a la database. (error: %s)", error);
        return 0;
    } else {
        Log("Roleplay FReZ", "la database na pas etait config dans le fichier databases.cfg");
    }
    new Handle:kv = CreateKeyValues("sql", "", "");
    KvSetString(kv, "driver", "mysql");
    KvSetString(kv, "host", "176.31.235.22");
    KvSetString(kv, "port", "3306");
    KvSetString(kv, "database", "rpfrez");
    KvSetString(kv, "user", "rpfrez");
    KvSetString(kv, "pass", "txsd2a2FqNR9RVFR");
    new Handle:hDatabase = SQL_ConnectCustom(kv, error, 255, true);
    CloseHandle(kv);
    if (hDatabase) {
        Log("Roleplay Start", "Connection r‚ussi  … la database de Thieus^ !", error);
        decl String:ipServeur[64];
        decl String:ipServReqt[64];
        Format(ipServeur, 64, "176.31.255.80:27014");
        decl String:dateDeFin[64];
        decl String:dateToday[64];
        new dateDuJour = 0;
        new dateDeF = 0;
        decl String:rek[128];
        Format(rek, 128, "SELECT date_exp, ip_serv FROM LocationRp WHERE id_location = 8");
        new Handle:query = SQL_Query(hDatabase, rek, -1);
        if (query) {
            if (SQL_FetchRow(query)) {
                SQL_FetchString(query, 0, dateDeFin, 64, 0);
                SQL_FetchString(query, 1, ipServReqt, 64, 0);
            }
            CloseHandle(query);
            CloseHandle(hDatabase);
            dateDeF = StringToInt(dateDeFin, 10);
            FormatTime(dateToday, 64, "%Y%m%d", GetTime({0,0}));
            dateDuJour = StringToInt(dateToday, 10);
            if (dateDeF - dateDuJour < 1) {
                Log("Roleplay Start", "Votre de d‚lai de location viens d'expir‚ veuillez contacter Thieus pour renouvel‚ votre plugin rp (%d)!", dateDeF - dateDuJour);
                return 0;
            }
            Log("Roleplay Start", "Date correct  (%d jours restant) !", dateDeF - dateDuJour);
            if (StrEqual(ipServeur, ipServReqt, true)) {
                Log("Roleplay Start", "Ip serveur ok !");
                CreationDatabaseRp();
                InserePorteDansladb();
                InsereMetier();
                InsereObjets();
                InsereCapital();
                inserLesZone();
                LoadKeyvalues();
                CreateAdminPanel();
                menuRecruteHospital();
                CreationMenuPourDonnerUnMetier();
                CreationMenuVendre();
                CreationMenuPourAcheterObjets();
                RecuperationDesPortes();
                Powersbeacon();
                modelDeProp();
                creategravityguncvar();
                CreateMenuNpcPrincipal();
                InitialeRaisonDeJail();
                TelechargerSkins();
                telechargerSon();
                CreationPlanqueBillet();
                InitialiseEventGuerre();
                m_vecOrigin = FindSendPropInfo("CBaseEntity", "m_vecOrigin", 0, 0, 0);
                CreateTimer(10, VerrouillageDeTouteLesPortes, any:0, 0);
                HookEvent("player_spawn", EventHook:197, EventHookMode:1);
                HookEvent("player_spawn", EventHook:199, EventHookMode:1);
                HookEvent("player_death", EventHook:191, EventHookMode:0);
                HookEvent("player_death", EventHook:193, EventHookMode:0);
                HookEvent("player_team", EventHook:201, EventHookMode:0);
                HookEvent("player_hurt", EventHook:195, EventHookMode:1);
                AddCommandListener(CommandListener:203, "say");
                AddCommandListener(CommandListener:205, "say_team");
                offsPunchAngle = FindSendPropInfo("CBasePlayer", "m_vecPunchAngle", 0, 0, 0);
                if (offsPunchAngle == -1) {
                    SetFailState("Couldn't find \"m_vecPunchAngle\"!");
                }
                g_textmsg = GetUserMessageId("TextMsg");
                HookUserMessage(g_textmsg, MsgHook:263, true, MsgPostHook:-1);
                CreateTimer(0.1, Timer_CheckAudio, any:0, 1);
                decl String:line[16];
                decl String:split[20][16];
                new Handle:file = OpenFile("cfg/roleplay/time.db", "r");
                ReadFileLine(file, line, 16);
                CloseHandle(file);
                ExplodeString(line, " ", split, 5, 16);
                annee = StringToInt(split[0][split], 10);
                jour = StringToInt(split[4], 10);
                nbmois = StringToInt(split[8], 10);
                minute = StringToInt(split[12], 10);
                Format(mois, 16, "%s", split[16]);
                decl String:admin[32];
                new Handle:fichier = OpenFile("cfg/roleplay/listeAdmin.db", "r");
                new i = 0;
                while (ReadFileLine(fichier, admin, 32)) {
                    ReplaceString(admin, 32, "\n", "", true);
                    ReplaceString(admin, 32, "\r", "", true);
                    if (!StrEqual(admin, "", true)) {
                        strcopy(ListeAdminRoleplay[i][0][0], 32, admin);
                    }
                    i++;
                }
                CloseHandle(fichier);
                g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
                if (g_iAccount == -1) {
                    Log("Roleplay FReZ", "Impossible de r‚cuperer m_iAccount");
                }
                smokesprite = PrecacheModel("sprites/smoke.vmt", false);
                g_bloodModel = PrecacheModel("sprites/blood.vmt", true);
                g_sprayModel = PrecacheModel("sprites/bloodspray.vmt", true);
                PluginLoaded = 1;
                Log("Roleplay FReZ", "Plugin loaded");
                CreateTimer(1, TickSecond, any:0, 1);
                CreateTimer(5, TimerPhone, any:0, 1);
                return 0;
            }
            Log("Roleplay Start", "Ip serveur differente %s  | %s !", ipServeur, ipServReqt);
            return 0;
        }
        SQL_GetError(hDatabase, error, 255);
        Log("Roleplay Admin", "Impossible de select date et ip du serveur -> error: %s", error);
        CloseHandle(query);
        return 0;
    }
    Log("Roleplay Start", "impossible de se connecter a la db de Thieus Veuillez le contacter erreur %s!", error);
    return 0;
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
    if (PluginLoaded) {
        strcopy(gameDesc, 64, "CSS-RP v2.0 by Thieus");
        return Action:1;
    }
    return Action:0;
}

public OnEntityCreated(entity, String:Classname[])
{
    if (StrEqual(Classname, "weapon_c4", true)) {
        SDKHook(entity, SDKHookType:10, SDKHookCB:261);
    }
    return 0;
}

public OnClientDisconnect(client)
{
    sauvegarderInfosClient(client);
    release(client);
    stopInscriptionEventGdG(client);
    clientPropC4[client] = -1;
    return 0;
}

public OnClientAuthorized(client, String:auth[])
{
    ajouterNouveauJoueur(client, auth);
    return 0;
}

public OnClientPutInServer(client)
{
    CreateTimer(6.5, choisirTeamSpawn, client, 0);
    grabbedentref[client] = -1;
    SDKHook(client, SDKHookType:4, SDKHookCB:247);
    SDKHook(client, SDKHookType:2, SDKHookCB:179);
    SDKHook(client, SDKHookType:2, SDKHookCB:241);
    SDKHook(client, SDKHookType:15, SDKHookCB:243);
    SDKHook(client, SDKHookType:16, SDKHookCB:245);
    clientPropC4[client] = -1;
    return 0;
}

public OnMapStart()
{
    prepatchsounds();
    PreChargerLesSkins();
    AutoExecConfig(true, "", "sourcemod");
    return 0;
}
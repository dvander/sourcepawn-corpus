public void OnPluginStart()
{
    //FindConVar("sv_sendtables").IntValue = 1;

    Handle hConfig = LoadGameConfigFile("spritescale");

    int spriteScaleOffset = GameConfGetOffset(hConfig, "SpriteScaleMax");
    int sendTableCRCOffset = GameConfGetOffset(hConfig, "SendTableCRC");
    Address g_SendTableCRC = GameConfGetAddress(hConfig, "g_SendTableCRC");
    Address m_SpriteScale = GameConfGetAddress(hConfig, "m_flSpriteScale");

    // 0x7f7fffff is the highest possible float value before inf
    StoreToAddress(m_SpriteScale + view_as<Address>(spriteScaleOffset), 0x7f7fffff, NumberType_Int32);

    // 12345 is a random and invalid CRC32 byte
    StoreToAddress(g_SendTableCRC+view_as<Address>(sendTableCRCOffset), 12345, NumberType_Int32);

    CloseHandle(hConfig);
}
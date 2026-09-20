-- AMBAGPT FIXED SCRIPT v2.2
-- Remake by AmbaGpt ~ Abyss Edition

-- ============================================================
-- FILE LOGIN
-- ============================================================

local nameFile = "/sdcard/Notes/gg_owner_login.txt"
local keyFile = "/sdcard/Notes/gg_owner_key.txt"

local loginKey = ""
local userName = ""


-- ============================================================
-- LOAD USERNAME
-- ============================================================

local file = io.open(nameFile, "r")

if file then
    userName = file:read("*l") or ""
    file:close()
end

userName = userName:match("^%s*(.-)%s*$") or ""


-- ============================================================
-- LOAD KEY
-- ============================================================

local keyRead = io.open(keyFile, "r")

if keyRead then
    loginKey = keyRead:read("*l") or ""
    keyRead:close()
end

loginKey = loginKey:match("^%s*(.-)%s*$") or ""


-- ============================================================
-- SISTEM LOGIN + BLACKLIST RENTRY
-- ============================================================

local BLACKLIST_URLS = {
    "https://rentry.co/6c8nvbwd",
    "https://rentry.org/6c8nvbwd/raw"
}

local RENTRY_RAW_ACCESS_CODE = ""


-- ============================================================
-- TELEGRAM
-- ============================================================

-- Masukkan BOT TOKEN BARU lu di sini
local BOT_TOKEN = "8831796936:AAHs-lAzXC7JcREgaY0oGUhpak9uoSJ_Aio"
local CHAT_ID = "8970090918"

local notifLogFile = "/sdcard/Notes/gg_notif_sent.txt"


-- ============================================================
-- FUNGSI UTILITY
-- ============================================================

local function trimText(value)

    value = tostring(value or "")

    return value:match("^%s*(.-)%s*$") or ""
end


-- ============================================================
-- USERNAME BELUM ADA
-- ============================================================
gg.setVisible(false)
if userName == "" then

    local promptInput = gg.prompt({
        " Masukkan Username:"
    }, {
        ""
    }, {
        "text"
    })

    if not promptInput
        or not promptInput[1]
        or trimText(promptInput[1]) == "" then

        gg.alert(
            " User cannot be empty!"
        )

        os.exit()
    end

    userName = trimText(promptInput[1])


    -- Simpan username
    local fileWrite = io.open(nameFile, "w")

    if fileWrite then

        fileWrite:write(userName)
        fileWrite:close()
    end
end


-- ============================================================
-- RENTRY HEADER
-- ============================================================

local function getRentryHeaders()

    local headers = {
        ["User-Agent"] =
            "Mozilla/5.0 (Linux; Android) AppleWebKit/537.36"
    }

    if trimText(RENTRY_RAW_ACCESS_CODE) ~= "" then

        headers["rentry-auth"] =
            trimText(RENTRY_RAW_ACCESS_CODE)
    end

    return headers
end


-- ============================================================
-- AMBIL IP PUBLIK
-- ============================================================

local function getUserIP()

    local ip = "UNKNOWN_IP"

    pcall(function()

        local res = gg.makeRequest(
            "https://api.ipify.org?format=text",
            {
                ["User-Agent"] =
                    "Mozilla/5.0 (Linux; Android)"
            }
        )

        if type(res) == "table"
            and res.code == 200
            and res.content then

            local candidate =
                trimText(res.content)

            if candidate ~= "" then
                ip = candidate
            end
        end
    end)

    return ip
end


-- ============================================================
-- LOGIN KEY VIA PASTEBIN
-- ============================================================

local KEY_URL =
    "https://pastebin.com/raw/REnycS4A"


local function checkPastebinKey(inputKey)

    local ok, response = pcall(function()

        local requestURL =
            KEY_URL .. "?_=" .. tostring(os.time())

        return gg.makeRequest(
            requestURL,
            {
                ["User-Agent"] =
                    "Mozilla/5.0 (Linux; Android)"
            }
        )
    end)

    if not ok
        or type(response) ~= "table"
        or response.code ~= 200
        or type(response.content) ~= "string" then

        return nil
    end

    local wantedKey =
        trimText(inputKey)

    for line in response.content:gmatch("[^\r\n]+") do

        local savedKey, expireDate =
            line:match("^%s*(.-)%s*|%s*(%d%d%d%d%-%d%d%-%d%d)%s*$")

        if savedKey
            and expireDate
            and trimText(savedKey) == wantedKey then

            local y, m, d =
                expireDate:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")

            y = tonumber(y)
            m = tonumber(m)
            d = tonumber(d)

            local expireTime =
                os.time({
                    year = y,
                    month = m,
                    day = d,
                    hour = 23,
                    min = 59,
                    sec = 59
                })

            local now =
                os.time()

            if now > expireTime then

                return false,
                    "expired",
                    expireDate
            end

            local remainingSeconds =
                expireTime - now

            local remainingDays =
                math.ceil(
                    remainingSeconds / 86400
                )

            return true,
                remainingDays,
                expireDate
        end
    end

    return false,
        "invalid",
        nil
end


-- ============================================================
-- CEK BLACKLIST
-- ============================================================

local function isValueBlacklisted(
    listContent,
    userNameValue,
    currentIP
)

    local wantedName =
        trimText(userNameValue):lower()

    local wantedIP =
        trimText(currentIP):lower()


    for line in tostring(
        listContent or ""
    ):gmatch("[^\r\n]+") do

        local entry =
            trimText(line)


        if entry ~= ""
            and not entry:match("^#")
            and not entry:match("^%-%-") then


            local normalized =
                entry:match(
                    "^[Nn][Aa][Mm][Ee]%s*[:=]%s*(.+)$"
                )

                or entry:match(
                    "^[Uu][Ss][Ee][Rr][Nn][Aa][Mm][Ee]%s*[:=]%s*(.+)$"
                )

                or entry:match(
                    "^[Ii][Pp]%s*[:=]%s*(.+)$"
                )

                or entry


            normalized =
                trimText(normalized):lower()


            if normalized == wantedName
                or normalized == wantedIP then

                return true, entry
            end
        end
    end


    return false, nil
end


-- ============================================================
-- HTML TO TEXT
-- ============================================================

local function htmlToPlainText(html)

    local body =
        tostring(html or "")


    local main =
        body:match(
            '<div[^>]-class="[^"]*entry%-text[^"]*"[^>]*>(.-)</div>%s*<div[^>]-class="text%-muted"'
        )


    if not main then

        main =
            body:match(
                '<div[^>]-class="[^"]*entry%-text[^"]*"[^>]*>(.*)</div>'
            )
    end


    if not main then
        return nil
    end


    main =
        main:gsub("</[Pp]%s*>", "\n")

    main =
        main:gsub("<br%s*/?>", "\n")

    main =
        main:gsub("</[Dd][Ii]%s*>", "\n")

    main =
        main:gsub("</[Tt][Rr]%s*>", "\n")

    main =
        main:gsub("</[Ll][Ii]%s*>", "\n")


    main =
        main:gsub(
            "<script.->.-</script>",
            ""
        )

    main =
        main:gsub(
            "<style.->.-</style>",
            ""
        )

    main =
        main:gsub(
            "<[^>]->",
            ""
        )


    main =
        main:gsub("&nbsp;", " ")

    main =
        main:gsub("&amp;", "&")

    main =
        main:gsub("&lt;", "<")

    main =
        main:gsub("&gt;", ">")

    main =
        main:gsub("&#39;", "'")

    main =
        main:gsub("&quot;", '"')


    return main
end


-- ============================================================
-- REQUEST RENTRY
-- ============================================================

local function requestRentry(url)

    local ok, response =
        pcall(function()

            return gg.makeRequest(
                url,
                getRentryHeaders()
            )
        end)


    if not ok then
        return nil
    end


    if type(response) ~= "table" then
        return nil
    end


    if response.code ~= 200 then
        return nil
    end


    local content =
        response.content


    if type(content) ~= "string"
        or trimText(content) == "" then

        return nil
    end


    local isHTML =
        content:find(
            "<html",
            1,
            true
        )

        or content:find(
            "<!DOCTYPE",
            1,
            true
        )

        or content:find(
            'class="entry-text"',
            1,
            true
        )


    if isHTML then

        local plain =
            htmlToPlainText(content)


        if plain
            and trimText(plain) ~= "" then

            return plain
        end


        return nil
    end


    return content
end


-- ============================================================
-- CHECK BLACKLIST
-- ============================================================

local function checkBlacklist(
    userNameValue,
    currentIP
)

    local serverConnected =
        false


    for _, url in ipairs(
        BLACKLIST_URLS
    ) do

        local content =
            requestRentry(url)


        if content then

            serverConnected =
                true


            local blocked,
                  matchedEntry =
                isValueBlacklisted(
                    content,
                    userNameValue,
                    currentIP
                )


            if blocked then

                return true,
                    matchedEntry
            end
        end
    end


    if serverConnected then

        return false, nil
    end


    return nil,
        "Server blacklist tidak dapat diakses"
end


-- ============================================================
-- CEK BLACKLIST USER
-- ============================================================

local currentIP =
    getUserIP()


local blacklistState,
      blacklistMatch =

    checkBlacklist(
        userName,
        currentIP
    )


if blacklistState == nil then

    gg.alert(
        " BLACKLIST SERVER ERROR\n\n" ..
        "Server blacklist tidak dapat diakses."
    )

    os.exit()
end


if blacklistState == true then

    gg.alert(
        " ACCESS BLOCKED\n\n" ..
        "Nama: " .. userName .. "\n" ..
        "IP: " .. currentIP .. "\n\n" ..
        "USERNAME: " ..
        tostring(blacklistMatch) ..
        "\n\n" ..
        "Lu udah gw blokir MAMPUSS!!! "
    )

    os.exit()
end


-- ============================================================
-- SISTEM KEY OTOMATIS
-- ============================================================

local keyDays = nil
local keyExpireDate = nil


-- ============================================================
-- CEK KEY TERSIMPAN
-- ============================================================

if loginKey ~= "" then

    local keyState,
          keyInfo,
          keyDate =
        checkPastebinKey(loginKey)


    -- KEY MASIH AKTIF
    if keyState == true then

        keyDays = keyInfo
        keyExpireDate = keyDate


    -- KEY SUDAH EXPIRED / TIDAK ADA
    elseif keyState == false then

        os.remove(keyFile)
        loginKey = ""

        if keyInfo == "expired" then

            gg.alert(
                "🔴 LOGIN KEY EXPIRED!\n\n" ..
                "Key: " .. loginKey .. "\n" ..
                "Expired: " ..
                tostring(keyDate)
            )

        end


    -- SERVER ERROR
    elseif keyState == nil then

        gg.alert(
            "❌ PASTEBIN SERVER ERROR!\n\n" ..
            "Gagal mengecek Login Key."
        )

        os.exit()
    end
end


-- ============================================================
-- MINTA KEY BARU
-- ============================================================

if loginKey == "" then

    local keyInput =
        gg.prompt({
            "🔑 Masukkan Login Key:"
        }, {
            ""
        }, {
            "text"
        })


    if not keyInput
        or not keyInput[1] then

        os.exit()
    end


    loginKey =
        trimText(keyInput[1])


    if loginKey == "" then

        gg.alert(
            "❌ Login Key tidak boleh kosong!"
        )

        os.exit()
    end


    -- ========================================================
    -- VALIDASI KEY BARU
    -- ========================================================

    local keyState,
          keyInfo,
          keyDate =
        checkPastebinKey(loginKey)


    if keyState == nil then

        gg.alert(
            "❌ Pastebin Key Server Error!"
        )

        os.exit()
    end


    if keyState == false then

        gg.alert(
            "❌ Login Key tidak valid / sudah expired!"
        )

        os.exit()
    end


    -- Simpan informasi masa berlaku
    keyDays = keyInfo
    keyExpireDate = keyDate


    -- ========================================================
    -- SIMPAN KEY
    -- ========================================================

    local keyWrite =
        io.open(keyFile, "w")


    if keyWrite then

        keyWrite:write(loginKey)
        keyWrite:close()
    end
end


-- ============================================================
-- LOGIN BERHASIL
-- ============================================================

local masaBerlaku

if tonumber(keyDays) == 1 then

    masaBerlaku = "1 Hari"

else

    masaBerlaku =
        tostring(keyDays) .. " Hari"
end


gg.alert(
    "✅ LOGIN BERHASIL\n\n" ..
    "👤 Username: " .. userName .. "\n" ..
    "🔑 Key: " .. loginKey .. "\n\n" ..
    "🟢 Key Aktif\n" ..
    "⏳ Masa Berlaku: " .. masaBerlaku .. "\n" ..
    "📅 Expired: " .. tostring(keyExpireDate)
)
-- ============================================================
-- TELEGRAM NOTIFICATION
-- ============================================================

local function sendLoginNotification()

    local logKey =
        userName .. "|" .. currentIP


    local isAlreadyNotified =
        false


    local readFile =
        io.open(
            notifLogFile,
            "r"
        )


    if readFile then

        for line in readFile:lines() do

            if line:match(
                "^%s*(.-)%s*$"
            ) == logKey then

                isAlreadyNotified =
                    true

                break
            end
        end


        readFile:close()
    end


    if not isAlreadyNotified then

        if trimText(BOT_TOKEN) == ""
            or trimText(CHAT_ID) == "" then

            return
        end


        local waktu =
            os.date("%d-%m-%Y")


        local jam =
            os.date("%H:%M:%S")


        local pesan =
            "LOGIN BARU%0A%0A" ..
            "Nama: " ..
            userName ..
            "%0A" ..
            "IP Address: " ..
            currentIP ..
            "%0A" ..
            "Tanggal: " ..
            waktu ..
            "%0A" ..
            "Jam: " ..
            jam ..
            "%0A" ..
            "Status: Menjalankan Script"


        local reqSuccess =
            false


        pcall(function()

            local url =
                "https://api.telegram.org/bot" ..
                BOT_TOKEN ..
                "/sendMessage?chat_id=" ..
                CHAT_ID ..
                "&text=" ..
                pesan


            local res =
                gg.makeRequest(url)


            if res
                and res.code == 200 then

                reqSuccess =
                    true
            end
        end)


        if reqSuccess then

            local writeFile =
                io.open(
                    notifLogFile,
                    "a"
                )


            if writeFile then

                writeFile:write(
                    logKey .. "\n"
                )

                writeFile:close()
            end
        end
    end
end


sendLoginNotification()
-- ============================================================
-- VARIABEL GLOBAL
-- ============================================================

local ORIGINAL_VALUES = {}
local TARGET_PACKAGE = "com.daerisoft.thespikerm"
local TARGET_VERSION = "[7.6.139] v7.6.139"

-- ============================================================
-- FUNGSI DASAR
-- ============================================================

function cleanup()
    gg.clearResults()
    if #ORIGINAL_VALUES > 0 then
        gg.setValues(ORIGINAL_VALUES)
        ORIGINAL_VALUES = {}
    end
    if #gg.getListItems() > 0 then
        gg.removeListItems(gg.getListItems())
    end
    gg.clearResults()
end

function welcome()
    gg.alert(
        "\n" ..
        "         Hanzz VIP Script \n" ..
        "\n\n" ..
        " WELCOME, PLAYER!\n\n" ..
        "Selamat datang di Hanzz VIP Script \n\n" ..
        " Version : 3.1\n" ..
        " Developer : Hanzz\n" ..
        " Status : VIP\n\n" ..
        "\n" ..
        " Thanks for using my script!\n" ..
        " Enjoy & have fun!\n" ..
        ""
    )
end

function loading()
    local frames = {
        "[] 0%",
        "[] 10%",
        "[] 20%",
        "[] 30%",
        "[] 40%",
        "[] 50%",
        "[] 60%",
        "[] 70%",
        "[] 80%",
        "[] 90%",
        "[] 100%"
    }

    for _, text in ipairs(frames) do
        gg.toast(" Hanzz VIP SCRIPT \n" .. text)
        gg.sleep(500)
    end

    gg.sleep(1000)
end

function setupMemory()
    gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_OTHER)
    gg.toast(" Memory Ready")
end

function blood()
    return " Hanzz VIP SCRIPT "
end

function waktuBold()
    return " " .. os.date("%H:%M:%S")
end

function range()
    while true do
        local pilih = gg.choice({
            " Set Range Android 12 - Ca_Alloc",
            " Set Range Android 13+ - Other",
        }, nil, blood() .. "\nPilih memory")

        if pilih == nil then
            gg.alert(" Pilih Salah Satu Opsi!")
        elseif pilih == 1 then
            gg.setRanges(gg.REGION_C_ALLOC)
            gg.alert(" Set Range Ca_Alloc Success")
            return
        elseif pilih == 2 then
            gg.setRanges(gg.REGION_OTHER)
            gg.alert(" Set Range Other Success")
            return
        end
    end
end
-- ============================================================
-- DAFTAR KODE MASTERY
-- ============================================================

local masteryList = {
    {nama = "VETERAN", kode = 1},
    {nama = "ELITE", kode = 2},
    {nama = "LEGEND", kode = 3},
    {nama = "CHAMPIONS", kode = 4},
    {nama = "???", kode = 26}
}

-- ============================================================
-- DAFTAR KODE CHARACTER (LENGKAP)
-- ============================================================

local namaKode = {
    [1] = "Siwoo",
    [2] = "Ohjun",
    [3] = "Jaeho",
    [4] = "jagang",
    [5] = "inryeok",
    [6] = "hyunso",
    [7] = "Jaehyun D",
    [8] = "Hanadu",
    [9] = "Jeongbin",
    [10] = "Yongsub",
    [11] = "Sehwan",
    [12] = "Eungseob",
    [13] = "Yeongjae",
    [14] = "KimMin",
    [15] = "KwonMin",
    [16] = "Kakek misterius",
    [19] = "Heesung",
    [20] = "Isijak",
    [21] = "Barae",
    [22] = "Proteo",
    [23] = "Squat",
    [24] = "BenchPress",
    [25] = "Sin Bada",
    [26] = "Pureum",
    [27] = "Jihwang",
    [28] = "Jaewook",
    [29] = "Yeongseok",
    [30] = "Jaehyun",
    [31] = "Ahyeon",
    [32] = "2KN03",
    [33] = "3C",
    [34] = "Jongha",
    [35] = "Seokgyu",
    [37] = "Cheolsu",
    [38] = "Ilbong",
    [39] = "Yonseok",
    [40] = "Lisia",
    [41] = "Sivir",
    [42] = "Arugur",
    [43] = "Robert",
    [44] = "Atis",
    [45] = "Alex",
    [47] = "Paul",
    [48] = "Kevin",
    [49] = "Brokoli",
    [50] = "Oasis",
    [51] = "Kim raksasa",
    [52] = "Big raksasa",
    [53] = "Choi raksasa",
    [54] = "Choji",
    [55] = "Donggeon",
    [56] = "Junseo",
    [57] = "Dong yeon",
    [58] = "Min gyu",
    [59] = "Cheolwan",
    [60] = "Howon",
    [61] = "UI seong",
    [62] = "Mirae",
    [63] = "Hang un",
    [64] = "Hyukjin",
    [65] = "Minjun",
    [66] = "Hyoung Sup",
    [67] = "Yongbi",
    [68] = "Jinwoo",
    [69] = "Hahyeon",
    [71] = "Boreum",
    [72] = "Seolhwa???",
    [73] = "CaC03",
    [74] = "jiho",
    [75] = "hyeonuk",
    [76] = "Dabin",
    [77] = "Junhyung",
    [78] = "Heontae",
    [79] = "Kwangin",
    [80] = "seonghun",
    [81] = "seongjwa",
    [82] = "seonggwang",
    [83] = "jini",
    [84] = "Soin",
    [85] = "Kakak kecil",
    [86] = "Gwangun",
    [87] = "Eun Seong",
    [88] = "Han beol",
    [89] = "Seon woo",
    [90] = "Seung Seon",
    [91] = "Jae seok",
    [92] = "Sachika",
    [93] = "Mizuho",
    [94] = "Amane",
    [95] = "Sohee",
    [96] = "Yamadera",
    [97] = "Shimura",
    [98] = "Nishikawa",
    [99] = "Nishikawa Old",
    [100] = "Dae hoon",
    [101] = "junhoo",
    [102] = "Shin sok",
    [103] = "Park cheetah",
    [104] = "luminor",
    [105] = "Pramadara",
    [106] = "Naegi",
    [107] = "Saesak",
    [108] = "Taichi",
    [109] = "Sota",
    [110] = "Jovan",
    [112] = "Nari",
    [113] = "Jangmi",
    [115] = "Seungmin",
    [157] = "Viola",
    [158] = "Leon",
    [159] = "Isabel",
    [160] = "Sanghyeon",
    [161] = "NN",
    [162] = "Oasis",
    [163] = "Roberto",
    [164] = "Nishikawa Black",
    [165] = "woo seok",
    [166] = "dupal",
    [167] = "seok gi",
    [168] = "Falco",
    [169] = "Olso",
    [170] = "Gialo",
    [171] = "Verde",
    [172] = "Mateo",
    [173] = "Marco",
    [174] = "Francesco",
    [175] = "gioseppe",
    [176] = "Ricardo",
    [177] = "Giovammi",
    [178] = "Alessia",
    [179] = "Valentino",
    [180] = "Leonardo",
    [181] = "Beneddeto",
    [182] = "Lorenzo",
    [183] = "Giacomo",
    [184] = "Federico",
    [185] = "Ranti",
    [186] = "Pianno",
    [187] = "Lazio",
    [188] = "Marcus",
    [189] = "Lucius",
    [190] = "Maximus",
    [191] = "Ignacio",
    [192] = "Leopoldo",
    [193] = "Anselmo",
    [194] = "NOT_LEON",
    [195] = "Valentina",
    [196] = "Alessia",
    [197] = "Andrea",
    [198] = "Alexandro",
    [199] = "DUMMY",
    [200] = "Seolhwa",
    [201] = "Kyle",
    [202] = "Taeho",
    [203] = "Ho yeon",
    [204] = "Mio",
    [205] = "Saeng won",
    [206] = "Jihwi",
    [207] = "Seon pung",
    [208] = "Suri",
    [209] = "Suhan",
    [210] = "Haesu",
    [211] = "Nari",
    [212] = "Hongsi",
    [213] = "Dae wong",
    [214] = "Kim Beom",
    [215] = "Sodam",
    [216] = "Dalji",
    [217] = "Daram",
    [218] = "Hanra",
    [219] = "Bidan",
    [220] = "Hurim",
    [221] = "Muyoung",
    [223] = "Donggwan",
    [224] = "Jinhwan",
    [225] = "Ryuhyeon",
    [226] = "Ryuhyeon???",
    [227] = "Ryuhyeon???2",
    [228] = "Dave",
    [229] = "Mike",
    [230] = "Sara SE",
    [231] = "Tania",
    [232] = "Clyde",
    [233] = "Liam",
    [234] = "Lucas",
    [235] = "Oliver",
    [236] = "Levi",
    [237] = "Dave???",
    [238] = "Mike???",
    [239] = "Gavin",
    [240] = "Calleb",
    [241] = "Isla",
    [242] = "Grace",
    [243] = "Evan",
    [244] = "Hahyeon",
    [245] = "Isabel Wedding",
    [246] = "Jaehyeon Training",
    [247] = "Nishikawa Old???",
    [248] = "Nishikawa HS",
    [249] = "Kazuki",
    [250] = "Cannon",
    [251] = "Jenny",
    [252] = "Ellio",
    [253] = "Milo zern",
    [254] = "Lene",
    [255] = "Oscar",
    [256] = "Leo Haas",
    [257] = "Dima orlo",
    [258] = "Jure",
    [259] = "Kira",
    [260] = "Mika Dorn",
    [261] = "Elva",
    [262] = "Oren bell",
    [263] = "Lars Grell",
    [264] = "Raul",
    [265] = "Kian",
    [266] = "Theo",
    [267] = "Sven",
    [268] = "Oasis",
    [269] = "Alessia",
    [270] = "Gelato",
    [271] = "Tomat",
    [272] = "Pizelle",
    [273] = "Tartufo",
    [274] = "Capucino",
    [275] = "Espreso",
    [276] = "Chianti",
    [277] = "Barollo",
    [278] = "Prosecco",
    [279] = "Saffira",
    [280] = "Cinnamiel",
    [281] = "Bazia",
    [282] = "Hari",
    [283] = "Crow",
    [284] = "Lucas",
    [285] = "Nikolai",
    [286] = "Zero",
    [287] = "Dahee",
    [288] = "Minerva",
    [289] = "Lucian",
    [290] = "Miren",
    [291] = "Rian",
    [292] = "Enzo",
    [293] = "Dante",
    [294] = "Raul",
    [295] = "Hari WS?",
    [296] = "Siwoo Phantom",
    [297] = "Bruno",
    [298] = "Tiziamo",
    [299] = "Massimo",
    [300] = "Fedele",
    [301] = "Salvatore",
    [302] = "Enrico",
    [303] = "Eustachio",
    [304] = "Montepull chiano",
    [305] = "Lasagna",
    [306] = "Pepino",
    [307] = "Pesto",
    [308] = "Buratta",
    [309] = "Fedele",
    [310] = "Eustachio",
    [311] = "Oasis",
    [312] = "Lisia",
    [313] = "NN Skin Summer",
    [314] = "Sung Han",
    [315] = "Duil",
    [316] = "Kim jisan",
    [317] = "Seolhwa MB",
    [318] = "Sohee",
    [319] = "Leon",
    [320] = "Viola",
    [321] = "Sanghyeon",
    [322] = "Claire",
    [323] = "Sif",
    [324] = "Raul Phantom",
    [325] = "Siwoo Phantom 2",
    [326] = "Valerio",
    [327] = "Fescari",
    [328] = "Obsidian",
    [329] = "Onyx",
    [330] = "Chriss",
    [331] = "Aria",
    [332] = "Raul 2",
    [333] = "Oasis?",
    [334] = "Isabel+",
    [335] = "Crow+",
    [336] = "Yongsub+",
    [337] = "Shimura?",
    [338] = "Panna cota",
    [339] = "Semifreddo",
    [340] = "Granita",
    [341] = "Mont blanc",
    [342] = "Cornetto",
    [343] = "Kalzone",
    [344] = "Prosciutto",
    [345] = "Milanese",
    [346] = "Cacciatore",
    [347] = "NN",
    [348] = "Chris",
    [349] = "Iris",
    [350] = "Yuri",
    [351] = "Sara WS",
    [352] = "Raul",
    [353] = "Volkov",
    [354] = "Ivan",
    [355] = "Sergei",
    [356] = "Aira",
    [357] = "Yamadera",
    [358] = "Mia",
    [359] = "Shimura",
    [360] = "Ellio Void",
    [361] = "Crow Void",
    [362] = "Hyeonuk",
    [363] = "Oasis No Skill",
    [364] = "Dahee Daeji High",
    [365] = "Wyat",
    [366] = "Shane",
    [367] = "Rex",
    [368] = "Walker",
    [369] = "Logan",
    [370] = "Daisy",
    [371] = "Ryuhyeon Gurun Rank D",
    [372] = "Sif Gurun Rank D",
    [373] = "Claire Gurun Rank D",
    [374] = "Saya",
    [375] = "Jihoon",
    [376] = "Haeun",
    [377] = "Younghoon",
    [378] = "Yongsub Story",
    [379] = "Jaeho",
    [380] = "Wakil Kepala Sekolah",
    [381] = "Haeun 2",
    [386] = "Kang Sejin",
    [387] = "Han Gitae",
    [388] = "Seo Yuna"
}

-- ============================================================
-- DAFTAR KARAKTER LIST (untuk scan)
-- ============================================================

local karakterList = {}
for kode, nama in pairs(namaKode) do
    karakterList[#karakterList + 1] = {
        nama = nama,
        kode = kode
    }
end

-- ============================================================
-- SCAN CHARACTER + MASTERY (SCAN ULANG BUAT MASTERY)
-- ============================================================

local hasilScanCharacter = {}

function scanCharacter()

    setupMemory()

    -- Tanya jumlah character
    local input = gg.prompt({
        "Jumlah character yang kamu punya:"
    }, {
        "50"
    }, {
        "number"
    })

    if input == nil then
        return
    end

    local jumlah = tonumber(input[1])

    if jumlah == nil or jumlah < 1 then
        gg.alert("❌ Jumlah tidak valid!")
        return
    end

    hasilScanCharacter = {}
    gg.clearResults()

    -- ============================================================
    -- SCAN 1: PAKE METODE 206398 (CHARACTER)
    -- ============================================================

    gg.searchNumber("206398", gg.TYPE_DOUBLE)
    local hasilAwal = gg.getResults(100000)

    if #hasilAwal == 0 then
        gg.alert("refine not found!")
        gg.clearResults()
        return
    end

    local offset1 = {}

    for _, v in ipairs(hasilAwal) do
        offset1[#offset1 + 1] = {
            address = v.address - 0x10,
            flags = gg.TYPE_DOUBLE
        }
    end

    local kandidat = {}
    local values1 = gg.getValues(offset1)

    for _, v in ipairs(values1) do
        if tonumber(v.value) == 226618 then
            kandidat[#kandidat + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE
            }
        end
    end

    if #kandidat == 0 then
        gg.alert("❌ 226618 tidak ditemukan!")
        gg.clearResults()
        return
    end

    local offset2 = {}

    for _, v in ipairs(kandidat) do
        offset2[#offset2 + 1] = {
            address = v.address + 0x70,
            flags = gg.TYPE_DOUBLE
        }
    end

    -- Scan karakter
    for _, v in ipairs(offset2) do
        for i = 1, jumlah do
            local alamat = v.address - (i * 0x130)

            local cek = gg.getValues({
                {
                    address = alamat,
                    flags = gg.TYPE_DOUBLE
                }
            })

            if cek[1] then
                local nilai = tonumber(cek[1].value)
                local nama = namaKode[nilai]

                if nama then
                    local sudahAda = false

                    for _, hasil in ipairs(hasilScanCharacter) do
                        if hasil.address == alamat then
                            sudahAda = true
                            break
                        end
                    end

                    if not sudahAda then
                        hasilScanCharacter[#hasilScanCharacter + 1] = {
                            nama = nama,
                            kode = nilai,
                            address = alamat
                        }
                    end
                end
            end
        end
    end

    gg.clearResults()

    if #hasilScanCharacter == 0 then
        gg.alert("❌ Tidak ada character terdeteksi!")
        return
    end

    -- Tampilkan hasil scan karakter
    local pesan = "🔎 HASIL SCAN KARAKTER\n\n"

    for i, v in ipairs(hasilScanCharacter) do
        pesan = pesan .. i .. ". " .. v.nama .. "\n"
    end

    gg.alert(pesan)

    -- Pilih karakter yang mau diedit
    local daftar = {}

    for i, v in ipairs(hasilScanCharacter) do
        daftar[i] = v.nama
    end

    local dipilih = gg.multiChoice(
        daftar,
        nil,
        "Pilih karakter yang mau diedit (centang)"
    )

    if dipilih == nil then
        return
    end

    local karakterTerpilih = {}

    -- Simpan kode karakter AWAL yang dipilih user
    local kodeKarakterAwal = nil
    local namaKarakterAwal = nil

    for i, selected in pairs(dipilih) do
        if selected then
            karakterTerpilih[#karakterTerpilih + 1] = hasilScanCharacter[i]
            if kodeKarakterAwal == nil then
                kodeKarakterAwal = hasilScanCharacter[i].kode
                namaKarakterAwal = hasilScanCharacter[i].nama
            end
        end
    end

    if #karakterTerpilih == 0 then
        gg.alert("❌ Tidak ada yang dipilih!")
        return
    end

    -- ============================================================
-- MENU EDIT KARAKTER - PILIH KATEGORI DULU
-- ============================================================

local pilihanEdit = gg.choice({
    "🔄 Ganti Karakter + Edit Stats",
    "📊 Edit Stats Only (tanpa ganti karakter)",
    "↩ Kembali"
}, nil, "PILIH MODE EDIT")

if pilihanEdit == nil or pilihanEdit == 3 then
    return
end

local targetKode = nil
local targetNama = nil

if pilihanEdit == 1 then
    -- ============================================================
    -- PILIH KATEGORI KARAKTER
    -- ============================================================

    local pilihKategori = gg.choice({
        "🏐 WS (Wing Spiker)",
        "🏐 MB (Middle Blocker)",
        "🏐 SE (Setter)",
        "↩ Batal"
    }, nil, "PILIH KATEGORI KARAKTER")

    if pilihKategori == nil or pilihKategori == 4 then
        return
    end

    -- ============================================================
    -- DAFTAR KARAKTER PER KATEGORI
    -- ============================================================

    local daftarWS = {
        {nama = "Nishikawa", kode = 98},
        {nama = "Kang Sejin", kode = 386},
        {nama = "Siwoo S+", kode = 325},
        {nama = "Raul", kode = 264},
        {nama = "Lucas", kode = 284},
        {nama = "Ryuhyun", kode = 225},
        {nama = "Sara WS", kode = 351},
        {nama = "Jaehyun", kode = 30},
        {nama = "Leon", kode = 158},
        {nama = "Dave", kode = 228},
        {nama = "Hongsi", kode = 212},
        {nama = "Nishikawa Old", kode = 99},
        {nama = "Isabel", kode = 159},
        {nama = "Dahee", kode = 287},
        {nama = "Raul Phantom", kode = 324},
        {nama = "Youngsub", kode = 10},
        {nama = "Wakil Kepala Sekolah", kode = 380},
        {nama = "Oasis", kode = 50},
        {nama = "Minjun", kode = 65},
        {nama = "Yoonseok", kode = 39},
        {nama = "Jenny", kode = 251},
        {nama = "Seo Yuna", kode = 388}
    }

    local daftarMB = {
        {nama = "Heesung", kode = 19},
        {nama = "Han Gitae", kode = 387},
        {nama = "Roberto", kode = 163},
        {nama = "Yamadera", kode = 96},
        {nama = "Sanghyeon", kode = 160},
        {nama = "Hanra", kode = 218},
        {nama = "Atis", kode = 44},
        {nama = "Claire", kode = 322},
        {nama = "Yuri", kode = 350},
        {nama = "Crow", kode = 283},
        {nama = "Hari", kode = 282},
        {nama = "Mike", kode = 229},
        {nama = "Clyde", kode = 232},
        {nama = "Han Gitae", kode = 387}
    }

    local daftarSE = {
        {nama = "Seolhwa", kode = 200},
        {nama = "Seo Yuna", kode = 388},
        {nama = "NN", kode = 161},
        {nama = "Viola", kode = 157},
        {nama = "Lisia", kode = 40},
        {nama = "Zero", kode = 286},
        {nama = "Sohee", kode = 95},
        {nama = "Sodam", kode = 215},
        {nama = "Ahyeon", kode = 31},
        {nama = "Ellio", kode = 252},
        {nama = "Tania", kode = 231},
        {nama = "Sara Se", kode = 230},
        {nama = "Muyoung", kode = 221},
        {nama = "Sif", kode = 323},
        {nama = "Iris", kode = 349},
        {nama = "Kang Sejin", kode = 386}
    }

    -- Pilih daftar sesuai kategori
    local daftarPilihan = {}
    if pilihKategori == 1 then
        daftarPilihan = daftarWS
    elseif pilihKategori == 2 then
        daftarPilihan = daftarMB
    elseif pilihKategori == 3 then
        daftarPilihan = daftarSE
    end

    -- ============================================================
    -- BUILD DAFTAR UNTUK GG.CHOICE
    -- ============================================================

    local menuKarakter = {}
    local kodeKarakter = {}

    for i, v in ipairs(daftarPilihan) do
        menuKarakter[i] = "⃝ " .. v.nama
        kodeKarakter[i] = v.kode
    end

    menuKarakter[#menuKarakter + 1] = "↩ Kembali"

    local pilihKarakter = gg.choice(
        menuKarakter,
        nil,
        "PILIH KARAKTER TUJUAN (" .. pilihKategori .. ")"
    )

    if pilihKarakter == nil or pilihKarakter == #menuKarakter then
        return
    end

    targetKode = kodeKarakter[pilihKarakter]
    targetNama = daftarPilihan[pilihKarakter].nama

    gg.toast(
        "✅ Target: " ..
        targetNama .. " [" .. targetKode .. "]"
    )
end

    -- ============================================================
    -- INPUT STATS
    -- ============================================================

    local daftarSkin =
    "🎨 DAFTAR SKIN\n\n" ..
    "-1 → Default/Tanpa skin\n" ..
    "1 → Nishikawa → High School\n" ..
    "2 → Isabel → Wedding\n" ..
    "3 → Jaehyun → Training\n" ..
    "4 → Nishikawa → Black\n" ..
    "7 → Ryuhyun → Chief Diciple\n" ..
    "9 → Jenny → Summer\n" ..
    "11 → NN → Summer\n" ..
    "14 → Hongsi → Maid\n" ..
    "17 → Jenny → Star\n" ..
    "18 → Hari → Star\n" ..
    "19 → Ryuhyun → Red hood\n" ..
    "21 → Claire → GodFather\n" ..
    "22 → Lucas → Summer"

    local statInput = gg.prompt({
        "Attack:",
        "Jump:",
        "Ascension:",
        "Defense:",
        daftarSkin .. "\n\nMasukkan ID Skin:"
    }, {
        "5000",
        "260",
        "5",
        "350",
        "-1"
    }, {
        "number",
        "number",
        "number",
        "number",
        "number"
    })

    if statInput == nil then
        return
    end

    local attack = tonumber(statInput[1]) or 0
    local jump = tonumber(statInput[2]) or 0
    local stamina = tonumber(statInput[3]) or 0
    local speed = tonumber(statInput[4]) or 0
    local skin = tonumber(statInput[5]) or 0

    -- Konfirmasi
    local pesanKonfirmasi = "⚠️ KONFIRMASI EDIT\n\n"
    pesanKonfirmasi = pesanKonfirmasi .. "Jumlah karakter: " .. #karakterTerpilih .. "\n"

    if targetNama then
        pesanKonfirmasi = pesanKonfirmasi .. "Ganti ke: " .. targetNama .. " (kode: " .. targetKode .. ")\n"
    else
        pesanKonfirmasi = pesanKonfirmasi .. "Ganti karakter: ❌ TIDAK\n"
    end

    pesanKonfirmasi = pesanKonfirmasi .. "\n📊 STATS:\n"
    pesanKonfirmasi = pesanKonfirmasi .. "Attack: " .. attack .. "\n"
    pesanKonfirmasi = pesanKonfirmasi .. "Jump: " .. jump .. "\n"
    pesanKonfirmasi = pesanKonfirmasi .. "Ascension: " .. stamina .. "\n"
    pesanKonfirmasi = pesanKonfirmasi .. "Defense: " .. speed .. "\n"

    local konfirmasi = gg.choice({
        "✅ Ya, lanjutkan!",
        "❌ Batal"
    }, nil, pesanKonfirmasi)

    if konfirmasi == nil or konfirmasi == 2 then
        gg.toast("❌ Dibatalkan")
        return
    end

    -- ============================================================
    -- EKSEKUSI EDIT KARAKTER (SEMENTARA)
    -- ============================================================

    local listEdit = {}
    local successCount = 0

    for _, karakter in ipairs(karakterTerpilih) do
        if karakter.address and karakter.address ~= 0 then

            if targetKode then
                listEdit[#listEdit + 1] = {
                    address = karakter.address,
                    flags = gg.TYPE_DOUBLE,
                    value = targetKode
                }
            end

            listEdit[#listEdit + 1] = {
                address = karakter.address - 0x80,
                flags = gg.TYPE_DOUBLE,
                value = attack
            }

            listEdit[#listEdit + 1] = {
                address = karakter.address - 0x10,
                flags = gg.TYPE_DOUBLE,
                value = jump
            }

            listEdit[#listEdit + 1] = {
                address = karakter.address - 0x70,
                flags = gg.TYPE_DOUBLE,
                value = stamina
            }

            listEdit[#listEdit + 1] = {
                address = karakter.address + 0x60,
                flags = gg.TYPE_DOUBLE,
                value = speed
            }

            listEdit[#listEdit + 1] = {
                address = karakter.address - 0x60,
                flags = gg.TYPE_DOUBLE,
                value = skin
            }

            successCount = successCount + 1
        end
    end

    if #listEdit == 0 then
        gg.alert("❌ Gagal!")
        return
    end

    local ok, err = pcall(function()
        gg.setValues(listEdit)
    end)

    if not ok then
        gg.alert("❌ Gagal mengedit!\n\n" .. tostring(err))
        return
    end

    gg.clearResults()

    local pesanHasil = "✅ EDIT KARAKTER BERHASIL!\n\n"
    pesanHasil = pesanHasil .. "Jumlah karakter: " .. successCount .. "\n"

    if targetNama then
        pesanHasil = pesanHasil .. "Diubah jadi: " .. targetNama .. "\n"
    end

    pesanHasil = pesanHasil .. "\n📊 STATS BARU:\n"
    pesanHasil = pesanHasil .. "Attack: " .. attack .. "\n"
    pesanHasil = pesanHasil .. "Jump: " .. jump .. "\n"
    pesanHasil = pesanHasil .. "Ascension: " .. stamina .. "\n"
    pesanHasil = pesanHasil .. "Speed: " .. speed .. "\n"

    gg.alert(pesanHasil)

    -- ============================================================
    -- TANYA MASTERY USER SEKARANG
    -- ============================================================

    local masterySekarang = gg.choice({
        "🔰 Rookie",
        "⭐ VETERAN",
        "⭐⭐ ELITE",
        "⭐⭐⭐ LEGEND",
        "↩ Batal"
    }, nil, "🏆 MASTERY SAAT INI?\n\nPilih mastery yang kamu punya sekarang:")

    if masterySekarang == nil or masterySekarang == 5 then
        gg.toast("❌ Dibatalkan")
        return
    end

    local kodeMasterySekarang = {
        [1] = 0,   -- Rookie
        [2] = 1,   -- VETERAN
        [3] = 2,   -- ELITE
        [4] = 3    -- LEGEND
    }

    local masteryValue = kodeMasterySekarang[masterySekarang]

    -- ============================================================
    -- SCAN 2: CARI KODE KARAKTER AWAL (MISAL LUCAS = 284)
    -- ============================================================

    gg.toast("🔍 Mencari kode karakter awal: " .. kodeKarakterAwal .. " (" .. namaKarakterAwal .. ")")

    -- Cari kode karakter AWAL yang dipilih user
    gg.searchNumber(tostring(kodeKarakterAwal), gg.TYPE_DOUBLE)
    local hasilKodeKarakter = gg.getResults(100000)

    if #hasilKodeKarakter == 0 then
        gg.alert("❌ Kode karakter " .. kodeKarakterAwal .. " tidak ditemukan!")
        return
    end

    gg.toast("✅ Ditemukan " .. #hasilKodeKarakter .. " hasil")

    -- ============================================================
    -- OFFSET -0x20 DARI ADDRESS KARAKTER → CARI MASTERY
    -- ============================================================

    local offsetMastery1 = {}

    for _, v in ipairs(hasilKodeKarakter) do
        offsetMastery1[#offsetMastery1 + 1] = {
            address = v.address - 0x20,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetMastery1)

    -- Cari kode mastery user (0/1/2/3)
    gg.refineNumber(tostring(masteryValue), gg.TYPE_DOUBLE)
    local hasilMastery1 = gg.getResults(3)

    if #hasilMastery1 == 0 then
        gg.alert("❌ Mastery tidak ditemukan!")
        return
    end

    gg.toast("✅ Ditemukan " .. #hasilMastery1 .. " hasil mastery")

    -- ============================================================
    -- OFFSET +0x30 DARI ADDRESS MASTERY → CARI MASTERY LAGI
    -- ============================================================

    local offsetMastery2 = {}

    for _, v in ipairs(hasilMastery1) do
        offsetMastery2[#offsetMastery2 + 1] = {
            address = v.address + 0x10,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetMastery2)

    -- Cari lagi kode mastery user
    gg.refineNumber(tostring(masteryValue), gg.TYPE_DOUBLE)
    local hasilMasteryFinal = gg.getResults(3)

    if #hasilMasteryFinal == 0 then
        gg.alert("❌ Mastery tidak ditemukan!")
        return
    end

    -- ============================================================
    -- PILIH MASTERY BARU
    -- ============================================================

    local daftarMasteryBaru = {
        "⭐ VETERAN [1]",
        "⭐⭐ ELITE [2]",
        "⭐⭐⭐ LEGEND [3]",
        "🏆 CHAMPIONS [4]",
        "❓ ??? [26]",
        "↩ Batal"
    }

    local pilihMasteryBaru = gg.choice(
        daftarMasteryBaru,
        nil,
        "PILIH MASTERY BARU"
    )

    if pilihMasteryBaru == nil or pilihMasteryBaru == 6 then
        gg.toast("❌ Dibatalkan")
        return
    end

    local kodeMasteryBaru = {
        [1] = 1,   -- VETERAN
        [2] = 2,   -- ELITE
        [3] = 3,   -- LEGEND
        [4] = 4,   -- CHAMPIONS
        [5] = 26   -- ???
    }

    local masteryBaruValue = kodeMasteryBaru[pilihMasteryBaru]
    local masteryBaruNama = daftarMasteryBaru[pilihMasteryBaru]

    -- ============================================================
    -- EDIT MASTERY + OFFSET -0x10 UNTUK EDIT KARAKTER TUJUAN
    -- ============================================================

    local listEditMastery = {}
    local listEditKarakterTujuan = {}

    for _, v in ipairs(hasilMasteryFinal) do
        if v.address and v.address ~= 0 then

            -- 1. Edit mastery
            listEditMastery[#listEditMastery + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE,
                value = masteryBaruValue
            }

            -- 2. Offset -0x10 dari address mastery → edit karakter tujuan
            if targetKode then
                listEditKarakterTujuan[#listEditKarakterTujuan + 1] = {
                    address = v.address + 0x10,
                    flags = gg.TYPE_DOUBLE,
                    value = targetKode
                }
            end
        end
    end

    -- Gabungkan semua edit
    local allEdit = {}
    for _, v in ipairs(listEditMastery) do
        allEdit[#allEdit + 1] = v
    end
    for _, v in ipairs(listEditKarakterTujuan) do
        allEdit[#allEdit + 1] = v
    end

    if #allEdit == 0 then
        gg.alert("❌ Gagal!")
        return
    end

    local okMastery, errMastery = pcall(function()
        gg.setValues(allEdit)
    end)

    if okMastery then
        gg.alert("✅ SEMUA BERHASIL!\n\n" ..
                 "Karakter awal: " .. namaKarakterAwal .. " [" .. kodeKarakterAwal .. "]\n" ..
                 "Karakter tujuan: " .. targetNama .. " [" .. targetKode .. "]\n" ..
                 "Mastery baru: " .. masteryBaruNama .. "\n\n" ..
                 "⚠️ Restart game atau pindah menu!")
    else
        gg.alert("❌ Gagal!\n\nError: " .. tostring(errMastery))
    end
end
-- ============================================================
-- MENU MASTERY (TANPA SCAN, LANGSUNG PILIH KARAKTER)
-- ============================================================

function masteryMenu()

    local pilih = gg.choice({
        "📋 Pilih karakter yang mau dikasih mastery",
        "↩ Kembali"
    }, nil, "MASTERY EDITOR")

    if pilih == nil or pilih == 2 then
        menuUtama()
        return
    end

    -- Pilih kategori karakter dulu
    local pilihKategori = gg.choice({
        "🏐 WS (Wing Spiker)",
        "🏐 MB (Middle Blocker)",
        "🏐 SE (Setter)",
        "↩ Batal"
    }, nil, "PILIH KATEGORI KARAKTER")

    if pilihKategori == nil or pilihKategori == 4 then
        return
    end

    -- ============================================================
    -- DAFTAR KARAKTER PER KATEGORI
    -- ============================================================

    local daftarWS = {
        {nama = "Nishikawa", kode = 98},
        {nama = "Siwoo S+", kode = 325},
        {nama = "Raul", kode = 264},
        {nama = "Lucas", kode = 284},
        {nama = "Ryuhyun", kode = 225},
        {nama = "Sara WS", kode = 351},
        {nama = "Jaehyun", kode = 30},
        {nama = "Leon", kode = 158},
        {nama = "Dave", kode = 228},
        {nama = "Hongsi", kode = 212},
        {nama = "Nishikawa Old", kode = 99},
        {nama = "Isabel", kode = 159},
        {nama = "Dahee", kode = 287},
        {nama = "Raul Phantom", kode = 324},
        {nama = "Youngsub", kode = 10},
        {nama = "Wakil Kepala Sekolah", kode = 380},
        {nama = "Oasis", kode = 50},
        {nama = "Minjun", kode = 65},
        {nama = "Yoonseok", kode = 39},
        {nama = "Jenny", kode = 251}
    }

    local daftarMB = {
        {nama = "Heesung", kode = 19},
        {nama = "Roberto", kode = 163},
        {nama = "Yamadera", kode = 96},
        {nama = "Sanghyeon", kode = 160},
        {nama = "Hanra", kode = 218},
        {nama = "Atis", kode = 44},
        {nama = "Claire", kode = 322},
        {nama = "Yuri", kode = 350},
        {nama = "Crow", kode = 283},
        {nama = "Hari", kode = 282},
        {nama = "Mike", kode = 229},
        {nama = "Clyde", kode = 232}
    }

    local daftarSE = {
        {nama = "Seolhwa", kode = 200},
        {nama = "NN", kode = 161},
        {nama = "Viola", kode = 157},
        {nama = "Lisia", kode = 40},
        {nama = "Zero", kode = 286},
        {nama = "Sohee", kode = 95},
        {nama = "Sodam", kode = 215},
        {nama = "Ahyeon", kode = 31},
        {nama = "Ellio", kode = 252},
        {nama = "Tania", kode = 231},
        {nama = "Sara Se", kode = 230},
        {nama = "Muyoung", kode = 221},
        {nama = "Sif", kode = 323},
        {nama = "Iris", kode = 349}
    }

    -- Pilih daftar sesuai kategori
    local daftarPilihan = {}
    if pilihKategori == 1 then
        daftarPilihan = daftarWS
    elseif pilihKategori == 2 then
        daftarPilihan = daftarMB
    elseif pilihKategori == 3 then
        daftarPilihan = daftarSE
    end

    -- Build menu karakter
    local menuKarakter = {}
    local kodeKarakter = {}

    for i, v in ipairs(daftarPilihan) do
        menuKarakter[i] = "⃝ " .. v.nama
        kodeKarakter[i] = v.kode
    end

    menuKarakter[#menuKarakter + 1] = "↩ Kembali"

    local pilihKarakter = gg.choice(
        menuKarakter,
        nil,
        "PILIH KARAKTER TUJUAN"
    )

    if pilihKarakter == nil or pilihKarakter == #menuKarakter then
        return
    end

    local targetKode = kodeKarakter[pilihKarakter]
    local targetNama = daftarPilihan[pilihKarakter].nama

    -- ============================================================
    -- TANYA MASTERY USER SEKARANG
    -- ============================================================

    local masterySekarang = gg.choice({
        "🔰 Rookie",
        "⭐ VETERAN",
        "⭐⭐ ELITE",
        "⭐⭐⭐ LEGEND",
        "↩ Batal"
    }, nil, "🏆 MASTERY SAAT INI?\n\nKarakter: " .. targetNama)

    if masterySekarang == nil or masterySekarang == 5 then
        gg.toast("❌ Dibatalkan")
        return
    end

    local kodeMasterySekarang = {
        [1] = 0,   -- Rookie
        [2] = 1,   -- VETERAN
        [3] = 2,   -- ELITE
        [4] = 3    -- LEGEND
    }

    local masteryValue = kodeMasterySekarang[masterySekarang]

    -- ============================================================
    -- CARI KODE KARAKTER DI MEMORY
    -- ============================================================

    gg.toast("🔍 Mencari karakter: " .. targetNama .. " (" .. targetKode .. ")")

    gg.clearResults()
    gg.searchNumber(tostring(targetKode), gg.TYPE_DOUBLE)
    local hasilKarakter = gg.getResults(100000)

    if #hasilKarakter == 0 then
        gg.alert("❌ Karakter " .. targetNama .. " tidak ditemukan!")
        return
    end

    gg.toast("✅ Ditemukan " .. #hasilKarakter .. " hasil")

    -- ============================================================
    -- OFFSET +0x20 DARI ADDRESS KARAKTER → CARI MASTERY
    -- ============================================================

    local offsetMastery1 = {}

    for _, v in ipairs(hasilKarakter) do
        offsetMastery1[#offsetMastery1 + 1] = {
            address = v.address - 0x20,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetMastery1)

    -- Cari kode mastery user (0/1/2/3)
    gg.refineNumber(tostring(masteryValue), gg.TYPE_DOUBLE)
    local hasilMastery1 = gg.getResults(1)

    if #hasilMastery1 == 0 then
        gg.alert("❌ Mastery tidak ditemukan!")
        return
    end

    gg.toast("✅ Ditemukan " .. #hasilMastery1 .. " hasil mastery")

    -- ============================================================
    -- OFFSET -0xA0 DARI ADDRESS MASTERY → CARI MASTERY LAGI
    -- ============================================================

    local offsetMastery2 = {}

    for _, v in ipairs(hasilMastery1) do
        offsetMastery2[#offsetMastery2 + 1] = {
            address = v.address + 0x10,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetMastery2)

    -- Cari lagi kode mastery user
    gg.refineNumber(tostring(masteryValue), gg.TYPE_DOUBLE)
    local hasilMasteryFinal = gg.getResults(1)

    if #hasilMasteryFinal == 0 then
        gg.alert("❌ Mastery tidak ditemukan!")
        return
    end

    -- ============================================================
    -- PILIH MASTERY BARU
    -- ============================================================

    local daftarMasteryBaru = {
        "⭐ VETERAN [1]",
        "⭐⭐ ELITE [2]",
        "⭐⭐⭐ LEGEND [3]",
        "🏆 CHAMPIONS [4]",
        "❓ ??? [26]",
        "↩ Batal"
    }

    local pilihMasteryBaru = gg.choice(
        daftarMasteryBaru,
        nil,
        "PILIH MASTERY BARU UNTUK " .. targetNama
    )

    if pilihMasteryBaru == nil or pilihMasteryBaru == 6 then
        gg.toast("❌ Dibatalkan")
        return
    end

    local kodeMasteryBaru = {
        [1] = 1,   -- VETERAN
        [2] = 2,   -- ELITE
        [3] = 3,   -- LEGEND
        [4] = 4,   -- CHAMPIONS
        [5] = 26   -- ???
    }

    local masteryBaruValue = kodeMasteryBaru[pilihMasteryBaru]
    local masteryBaruNama = daftarMasteryBaru[pilihMasteryBaru]

    -- ============================================================
    -- EDIT MASTERY
    -- ============================================================

    local listEditMastery = {}

    for _, v in ipairs(hasilMasteryFinal) do
        if v.address and v.address ~= 0 then
            listEditMastery[#listEditMastery + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE,
                value = masteryBaruValue
            }
        end
    end

    if #listEditMastery == 0 then
        gg.alert("❌ Gagal!")
        return
    end

    local okMastery, errMastery = pcall(function()
        gg.setValues(listEditMastery)
    end)

    if okMastery then
        gg.alert("✅ MASTERY BERHASIL DIUBAH!\n\n" ..
                 "Karakter: " .. targetNama .. "\n" ..
                 "Mastery baru: " .. masteryBaruNama .. "\n\n" ..
                 "⚠️ Restart game atau pindah menu!")
    else
        gg.alert("❌ Gagal edit mastery!\n\nError: " .. tostring(errMastery))
    end
end
-- ============================================================
-- FUNGSI CHHAR - CARI 206398, OFFSET PER KARAKTER
-- ============================================================
function chhar(kodeTarget, namaTarget)
    setupMemory()
    gg.clearResults()

    local offsetKarakter = {
        [1] = -0xD0,  -- Siwoo
        [2] = -0x200,  -- Ohjun
        [3] = -0x330   -- Jaeho
    }

    local offset = offsetKarakter[kodeTarget]

    if not offset then
        gg.alert(" Kode " .. tostring(kodeTarget) .. " nggak ada di daftar offset!")
        return nil
    end

    gg.toast(" Mencari")
    gg.searchNumber("206398", gg.TYPE_DOUBLE)
    local hasilAwal = gg.getResults(100000)

    if #hasilAwal == 0 then
        gg.alert(" Refine Not Found!")
        gg.clearResults()
        return nil
    end

    gg.toast(" Ditemukan " .. #hasilAwal .. " hasil")

    local offsetList = {}
    for _, v in ipairs(hasilAwal) do
        offsetList[#offsetList + 1] = {
            address = v.address + offset,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.toast(" Karakter siap")

    local values = gg.getValues(offsetList)
    local kandidat = {}

    for _, v in ipairs(values) do
        if tonumber(v.value) == tonumber(kodeTarget) then
            kandidat[#kandidat + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE
            }
        end
    end

    if #kandidat == 0 then
        gg.alert(" Kode " .. kodeTarget .. " (" .. (namaTarget or "?") .. ") tidak ditemukan!")
        gg.clearResults()
        return nil
    end

    gg.toast(" Ditemukan " .. #kandidat .. " kandidat")

    local patokan = kandidat[1].address

    gg.clearResults()
    gg.toast(" Patokan " .. (namaTarget or "") .. " diambil!")

    return patokan
end

-- ============================================================
-- DAFTAR KARAKTER TUJUAN PER POSISI
-- ============================================================

-- WS (Wing Spiker) - buat Siwoo
local daftarWS = {
    {nama = "Nishikawa", kode = 98},
    {nama = "Siwoo S+", kode = 325},
    {nama = "Raul", kode = 264},
    {nama = "Lucas", kode = 284},
    {nama = "Ryuhyun", kode = 225},
    {nama = "Sara WS", kode = 351},
    {nama = "Jaehyun", kode = 30},
    {nama = "Leon", kode = 158},
    {nama = "Dave", kode = 228},
    {nama = "Hongsi", kode = 212},
    {nama = "Nishikawa Old", kode = 99},
    {nama = "Isabel", kode = 159},
    {nama = "Dahee", kode = 287},
    {nama = "Raul Phantom", kode = 324},
    {nama = "Youngsub", kode = 10},
    {nama = "Wakil Kepala Sekolah", kode = 380},
    {nama = "Oasis", kode = 50},
    {nama = "Minjun", kode = 65},
    {nama = "Yoonseok", kode = 39},
    {nama = "Jenny", kode = 251},
    {nama = "Seo Yuna", kode = 388}
}

-- MB (Middle Blocker) - buat Ohjun
local daftarMB = {
    {nama = "Heesung", kode = 19},
    {nama = "Roberto", kode = 163},
    {nama = "Yamadera", kode = 96},
    {nama = "Sanghyeon", kode = 160},
    {nama = "Hanra", kode = 218},
    {nama = "Atis", kode = 44},
    {nama = "Claire", kode = 322},
    {nama = "Yuri", kode = 350},
    {nama = "Crow", kode = 283},
    {nama = "Hari", kode = 282},
    {nama = "Mike", kode = 229},
    {nama = "Clyde", kode = 232},
    {nama = "Han Gitae", kode = 387}
}

-- SE (Setter) - buat Jaeho
local daftarSE = {
    {nama = "Seolhwa", kode = 200},
    {nama = "NN", kode = 161},
    {nama = "Viola", kode = 157},
    {nama = "Lisia", kode = 40},
    {nama = "Zero", kode = 286},
    {nama = "Sohee", kode = 95},
    {nama = "Sodam", kode = 215},
    {nama = "Ahyeon", kode = 31},
    {nama = "Ellio", kode = 252},
    {nama = "Tania", kode = 231},
    {nama = "Sara Se", kode = 230},
    {nama = "Muyoung", kode = 221},
    {nama = "Sif", kode = 323},
    {nama = "Iris", kode = 349},
    {nama = "Kang Sejin", kode = 386}
}

-- ============================================================
-- CHARACTER (VERSI BARU - DAFTAR TUJUAN PER POSISI)
-- ============================================================
function character(nama, kode, kode2, ofss, punyaSkin)
    -- Step 1: Cari patokan dulu
    local patokan = chhar(kode, nama)

    if patokan == nil then
        gg.alert(" Gagal menemukan " .. nama .. "!")
        return
    end

    gg.toast(" Patokan " .. nama .. " ketemu!")

    -- ============================================================
    -- Step 2: Tentukan daftar tujuan berdasarkan karakter
    -- ============================================================
    local daftarTujuan = {}

    if kode == 1 then
        -- Siwoo  WS
        daftarTujuan = daftarWS
    elseif kode == 2 then
        -- Ohjun  MB
        daftarTujuan = daftarMB
    elseif kode == 3 then
        -- Jaeho  SE
        daftarTujuan = daftarSE
    else
        gg.alert(" Karakter " .. nama .. " nggak ada daftar tujuannya!")
        return
    end

    -- ============================================================
    -- Step 3: Pilih karakter tujuan
    -- ============================================================
    local menuKarakter = {}
    local kodeKarakterTujuan = {}

    for i, v in ipairs(daftarTujuan) do
        menuKarakter[i] = " " .. v.nama
        kodeKarakterTujuan[i] = v.kode
    end

    menuKarakter[#menuKarakter + 1] = " Nggak ganti karakter"
    menuKarakter[#menuKarakter + 1] = " Batal"

    local pilihKarakter = gg.choice(
        menuKarakter,
        nil,
        "MAU DIUBAH JADI SIAPA?\n\nKarakter asal: " .. nama
    )

    if pilihKarakter == nil or pilihKarakter == #menuKarakter then
        gg.toast(" Dibatalkan")
        return
    end

    local targetKode = nil
    local targetNama = nil

    if pilihKarakter < #menuKarakter - 1 then
        targetKode = kodeKarakterTujuan[pilihKarakter]
        targetNama = daftarTujuan[pilihKarakter].nama

        gg.toast(" Ganti ke: " .. targetNama .. " (" .. targetKode .. ")")
    else
        gg.toast(" Karakter nggak diganti")
    end

    -- ============================================================
    -- Step 4: Pilih ability & skin yang mau diedit
    -- ============================================================
    local pilihanEdit = gg.multiChoice({
        " Attack",
        " Jump",
        " Ascension",
        " Defense",
        " Skin"
    }, nil, "MAU EDIT APA?\n\nKarakter: " .. nama)

    if pilihanEdit == nil then
        gg.toast(" Dibatalkan")
        return
    end

    -- ============================================================
    -- Step 5: Kumpulkan edit
    -- ============================================================
    local edit = {}

    -- Ganti karakter
    if targetKode then
        edit[#edit + 1] = {
            address = patokan,
            flags = gg.TYPE_DOUBLE,
            value = targetKode
        }
    end

    -- Attack
    if pilihanEdit[1] then
        local input = gg.prompt({" Attack:"}, {"5000"}, {"number"})
        if input then
            edit[#edit + 1] = {
                address = patokan - 0x80,
                flags = gg.TYPE_DOUBLE,
                value = tonumber(input[1]) or 0
            }
        end
    end

    -- Jump
    if pilihanEdit[2] then
        local input = gg.prompt({" Jump:"}, {"260"}, {"number"})
        if input then
            edit[#edit + 1] = {
                address = patokan - 0x10,
                flags = gg.TYPE_DOUBLE,
                value = tonumber(input[1]) or 0
            }
        end
    end

    -- Ascension
    if pilihanEdit[3] then
        local input = gg.prompt({" Ascension:"}, {"5"}, {"number"})
        if input then
            edit[#edit + 1] = {
                address = patokan - 0x70,
                flags = gg.TYPE_DOUBLE,
                value = tonumber(input[1]) or 0
            }
        end
    end

    -- Defense
    if pilihanEdit[4] then
        local input = gg.prompt({" Defense:"}, {"350"}, {"number"})
        if input then
            edit[#edit + 1] = {
                address = patokan + 0x60,
                flags = gg.TYPE_DOUBLE,
                value = tonumber(input[1]) or 0
            }
        end
    end

    -- Skin
    if pilihanEdit[5] then
        local daftarSkin =
        " DAFTAR SKIN\n\n" ..
        "-1  Default/Tanpa skin\n" ..
        "1  Nishikawa  High School\n" ..
        "2  Isabel  Wedding\n" ..
        "3  Jaehyun  Training\n" ..
        "4  Nishikawa  Black\n" ..
        "7  Ryuhyun  Chief Diciple\n" ..
        "9  Jenny  Summer\n" ..
        "11  NN  Summer\n" ..
        "14  Hongsi  Maid\n" ..
        "17  Jenny  Star\n" ..
        "18  Hari  Star\n" ..
        "19  Ryuhyun  Red hood\n" ..
        "21  Claire  GodFather\n" ..
        "22  Lucas  Summer"

        gg.alert(daftarSkin)

        local inputSkin = gg.prompt({
            "Masukkan ID Skin:"
        }, {"-1 (Tanpa Skin)"}, {"number"})

        if inputSkin then
            edit[#edit + 1] = {
                address = patokan - 0x60,
                flags = gg.TYPE_DOUBLE,
                value = tonumber(inputSkin[1]) or -1
            }
        end
    end

    -- ============================================================
    -- Step 6: Eksekusi edit
    -- ============================================================
    if #edit == 0 then
        gg.alert(" Nggak ada yang diedit!")
        return
    end

    local ok, err = pcall(function()
        gg.setValues(edit)
    end)

    if ok then
        local pesanHasil = " BERHASIL!\n\n"
        pesanHasil = pesanHasil .. "Karakter asal: " .. nama .. "\n"

        if targetNama then
            pesanHasil = pesanHasil .. "Diubah jadi: " .. targetNama .. "\n"
        end

        pesanHasil = pesanHasil .. "Jumlah edit: " .. #edit .. "\n\n"
        pesanHasil = pesanHasil .. " Restart game atau pindah menu!"

        gg.alert(pesanHasil)
    else
        gg.alert(" Gagal!\n\nError: " .. tostring(err))
    end

    gg.clearResults()
    menuUtama()
end
-- ============================================================
-- FUNGSI WS MASTERY
-- ============================================================

function chharM(kodechar, nilaiBaru, offs)
    gg.clearResults()

    gg.searchNumber("12484", gg.TYPE_DOUBLE)
    local r1 = gg.getResults(100000)

    if #r1 == 0 then
        gg.alert(" 12484 tidak ditemukan!")
        return nil
    end

    local offset10a = {}

    for _, v in ipairs(r1) do
        offset10a[#offset10a + 1] = {
            address = v.address + 0x160,
            flags = gg.TYPE_DOUBLE
        }
    end

    local hasil50 = {}
    local values = gg.getValues(offset10a)

    for _, v in ipairs(values) do
        if v.value == 10619 then
            hasil50[#hasil50 + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE
            }
        end
    end

    if #hasil50 == 0 then
        gg.alert(" 10619 tidak ditemukan!")
        gg.clearResults()
        return nil
    end

    local offsetChar = {}

    for _, v in ipairs(hasil50) do
        offsetChar[#offsetChar + 1] = {
            address = v.address + offs,
            flags = gg.TYPE_DOUBLE
        }
    end

    local valuesChar = gg.getValues(offsetChar)
    local hasilChar = {}

    for _, v in ipairs(valuesChar) do
        if v.value == kodechar then
            hasilChar[#hasilChar + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE,
                value = nilaiBaru
            }
        end
    end

    if #hasilChar == 0 then
        gg.alert(" Kode " .. kodechar .. " tidak ditemukan!")
        gg.clearResults()
        return nil
    end

    gg.setValues(hasilChar)

    local addr_patokan = hasilChar[1].address

    gg.clearResults()

    gg.toast(" Character ditemukan!")

    return addr_patokan
end

-- ============================================================
-- CHARACTER M (DENGAN MASTERY)
-- ============================================================

function characterM(nama, kode, nilaiBaru, offs, offsM, offsA, offsC, punyaSkin)
    local skinValue = nil

    if punyaSkin then
        local daftarSkin =
        " DAFTAR SKIN\n\n" ..
        "-1  Default/Tanpa skin\n" ..
        "1  Nishikawa  High School\n" ..
        "2  Isabel  Wedding\n" ..
        "3  Jaehyun  Training\n" ..
        "4  Nishikawa  Black\n" ..
        "7  Ryuhyun  Chief Diciple\n" ..
        "9  Jenny  Summer\n" ..
        "11  NN  Summer\n" ..
        "14  Hongsi  Maid\n" ..
        "17  Jenny  Star\n" ..
        "18  Hari  Star\n" ..
        "19  Ryuhyun  Red hood\n" ..
        "21  Claire  GodFather\n" ..
        "22  Lucas  Summer"

        gg.alert(daftarSkin)

        local skin = gg.choice({
            "Tanpa Skin",
            "Nishi - Skin HS",
            "Isabel - Wedding",
            "Jaehyun - Training",
            "Nishi - Skin Black",
            "Ryuhyun - Chief Diciple",
            "Jenny - Summer",
            "NN - Summer",
            "Hongsi - Maid",
            "Jenny - Star",
            "Hari - Star",
            "Ryuhyun - Red hood",
            "Claire - GodFather",
            "Lucas - Summer",
            " Kembali"
        }, nil, nama .. " - PILIH SKIN")

        if skin == nil or skin == 15 then
            gg.clearResults()
            gg.toast(" Dibatalkan")
            charMenu()
            return
        elseif skin == 1 then
            skinValue = -1
        elseif skin == 2 then
            skinValue = 1
        elseif skin == 3 then
            skinValue = 2
        elseif skin == 4 then
            skinValue = 3
        elseif skin == 5 then
            skinValue = 4
        elseif skin == 6 then
            skinValue = 7
        elseif skin == 7 then
            skinValue = 9
        elseif skin == 8 then
            skinValue = 11
        elseif skin == 9 then
            skinValue = 14
        elseif skin == 10 then
            skinValue = 17
        elseif skin == 11 then
            skinValue = 18
        elseif skin == 12 then
            skinValue = 19
        elseif skin == 13 then
            skinValue = 21
        elseif skin == 14 then
            skinValue = 22
        end
    end

    local input = gg.prompt({
        "Attack :",
        "Jump :",
        "Ascension :",
        "Defense :",
        "Speed :"
    }, {
        "500",
        "80",
        "5",
        "350",
        "70"
    }, {
        "number",
        "number",
        "number",
        "number",
        "number"
    })

    if input == nil then
        return
    end

    local patokan = chharM(kode, nilaiBaru, offs)

    if patokan == nil then
        gg.alert(" Gagal menemukan " .. nama .. "!")
        return
    end

    local edit = {
        {
            address = patokan - 0x80,
            flags = gg.TYPE_DOUBLE,
            value = input[1]
        },
        {
            address = patokan - 0x50,
            flags = gg.TYPE_DOUBLE,
            value = input[2]
        },
        {
            address = patokan - 0xE0,
            flags = gg.TYPE_DOUBLE,
            value = input[3]
        },
        {
            address = patokan + 0x10,
            flags = gg.TYPE_DOUBLE,
            value = input[4]
        },
        {
            address = patokan - 0xD0,
            flags = gg.TYPE_DOUBLE,
            value = input[5]
        }
    }

    if skinValue ~= nil then
        edit[#edit + 1] = {
            address = patokan - 0xC0,
            flags = gg.TYPE_DOUBLE,
            value = skinValue
        }
    end

    gg.setValues(edit)

    gg.toast(" " .. nama .. " berhasil diubah!")

    if offsM ~= nil and offsA ~= nil and offsC ~= nil then
        mastery(offsM, offsA, offsC)
    end

    gg.alert(
        "BERHASIL!\n\n" ..
        "Character : " .. nama .. "\n" ..
        "Attack : " .. input[1] .. "\n" ..
        "Jump : " .. input[2] .. "\n" ..
        "Ascension : " .. input[3] .. "\n" ..
        "Defense : " .. input[4]
    )

    gg.clearResults()
    menuUtama()
end
-- ============================================================
-- MASTERY FUNCTION
-- ============================================================

function pilihMastery()
    local pilihan = gg.choice({
        "1. VETERAN",
        "2. ELITE",
        "3. LEGEND",
        "4. CHAMPIONS",
        "5. ???"
    }, nil, "PILIH MASTERY")

    if pilihan == nil then
        return nil
    end

    local nilai = {
        [1] = 1,
        [2] = 2,
        [3] = 3,
        [4] = 4,
        [5] = 26
    }

    return nilai[pilihan]
end

function mastery(offsM, offsA, offsC)
    local nilaiMastery = pilihMastery()

    if nilaiMastery == nil then
        gg.toast(" Mastery dibatalkan")
        return
    end

    gg.clearResults()

    gg.searchNumber("404", gg.TYPE_DOUBLE)
    local hasil284 = gg.getResults(100000)

    if #hasil284 == 0 then
        gg.alert(" 404 tidak ditemukan!")
        return
    end

    local offset40 = {}

    for _, v in ipairs(hasil284) do
        offset40[#offset40 + 1] = {
            address = v.address + 0x20,
            flags = gg.TYPE_DOUBLE
        }
    end

    local hasil303 = {}

    for _, v in ipairs(gg.getValues(offset40)) do
        if v.value == 3550 then
            hasil303[#hasil303 + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE
            }
        end
    end

    if #hasil303 == 0 then
        gg.alert(" 3550 tidak ditemukan!")
        gg.clearResults()
        return
    end

    local target = {}

    for _, v in ipairs(hasil303) do
        target[#target + 1] = {
            address = v.address + offsM,
            flags = gg.TYPE_DOUBLE,
            value = nilaiMastery
        }
    end

    gg.setValues(target)

    local target1 = {}

    for _, v in ipairs(target) do
        target1[#target1 + 1] = {
            address = v.address + offsA,
            flags = gg.TYPE_DOUBLE,
            value = offsC
        }
    end

    gg.setValues(target1)

    gg.toast(" Berhasil ubah mastery!")
    gg.alert(" BERHASIL UBAH MASTERY")

    gg.clearResults()
end
-- ============================================================
-- MENU KARAKTER
-- ============================================================

function charMenu()
    local pilih = gg.choice({
        " Siwoo  Wing Spiker",
        " Ohjun  Middle Blocker",
        " Jaeho  Setter",
        " Scan character/other",
        " Return"
    }, nil, blood() .. "\n" .. "Main Menu Character")

    if pilih == nil then
        return
    elseif pilih == 1 then
        -- Siwoo
        gg.toast(" Siwoo selected!")
        character("Siwoo", 1, 1, 0, false)
    elseif pilih == 2 then
        -- Ohjun
        gg.toast(" Ohjun selected!")
        character("Ohjun", 2, 2, 0, false)
    elseif pilih == 3 then
        -- Jaeho
        gg.toast(" Jaeho selected!")
        character("Jaeho", 3, 3, 0, false)
    elseif pilih == 4 then
        scanCharacter()
    elseif pilih == 5 then
        menuUtama()
    end
end
-- ============================================================
-- BALL SKIN MENU
-- ============================================================

function ball()
    gg.clearResults()

    gg.searchNumber("0.55", gg.TYPE_DOUBLE)
    local hasil055 = gg.getResults(100000)

    if #hasil055 == 0 then
        gg.alert(" 0.55 tidak ditemukan!")
        return
    end

    local hasilOffset30 = {}

    for _, v in ipairs(hasil055) do
        hasilOffset30[#hasilOffset30 + 1] = {
            address = v.address + 0x30,
            flags = gg.TYPE_DOUBLE
        }
    end

    local hasilMinus4 = {}

    for _, v in ipairs(gg.getValues(hasilOffset30)) do
        if v.value == -4 then
            hasilMinus4[#hasilMinus4 + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE
            }
        end
    end

    if #hasilMinus4 == 0 then
        gg.alert(" -4 tidak ditemukan!")
        gg.clearResults()
        return
    end

    local hasilAkhir = {}

    for _, v in ipairs(hasilMinus4) do
        hasilAkhir[#hasilAkhir + 1] = {
            address = v.address - 0x50,
            flags = gg.TYPE_DOUBLE
        }
    end

    local input = gg.prompt(
        {
            "Ketik ID Skin Bola 1-50"
        },
        {
            "1"
        },
        {
            "number"
        }
    )

    if input == nil then
        return
    end

    local nilai = tonumber(input[1])

    if nilai == nil or nilai < 1 or nilai > 50 then
        gg.alert(" ID skin hanya 1-50!")
        return
    end

    local edit = {}

    for _, v in ipairs(hasilAkhir) do
        edit[#edit + 1] = {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = nilai
        }
    end

    gg.setValues(edit)

    gg.toast(" ID Skin Bola berhasil diubah menjadi " .. nilai)

    gg.clearResults()
end

-- ============================================================
-- BACKGROUND MENU
-- ============================================================

function bacMenu()
    gg.clearResults()

    gg.searchNumber("91", gg.TYPE_DOUBLE)
    local hasil91 = gg.getResults(100000)

    if #hasil91 == 0 then
        gg.alert("Background tidak ditemukan!")
        return
    end

    local offset10 = {}

    for _, v in ipairs(hasil91) do
        offset10[#offset10 + 1] = {
            address = v.address - 0x10,
            flags = gg.TYPE_DOUBLE
        }
    end

    local cari115 = {}

    for _, v in ipairs(gg.getValues(offset10)) do
        if v.value == 115 then
            cari115[#cari115 + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE
            }
        end
    end

    if #cari115 == 0 then
        gg.alert("115 tidak ditemukan!")
        gg.clearResults()
        return
    end

    local hasilAkhir = {}

    for _, v in ipairs(cari115) do
        hasilAkhir[#hasilAkhir + 1] = {
            address = v.address - 0x230,
            flags = gg.TYPE_DOUBLE
        }
    end

    local nilai

    while true do
        local input = gg.prompt({
            "Pilih ID Background 1-20"
        }, {
            "1"
        }, {
            "number"
        })

        if input == nil then
            gg.clearResults()
            return
        end

        nilai = tonumber(input[1])

        if nilai ~= nil and nilai >= 1 and nilai <= 20 then
            break
        end

        gg.alert(" ID Background hanya 1-20!")
    end

    for _, v in ipairs(hasilAkhir) do
        v.value = nilai
    end

    gg.setValues(hasilAkhir)

    gg.alert(" ID Background berhasil diubah menjadi " .. nilai)

    gg.clearResults()
end

-- ============================================================
-- CHANGE SCORE
-- ============================================================

local savedScore = nil

function saveScore()
    gg.clearResults()

    gg.searchNumber("1235", gg.TYPE_DOUBLE)
    local hasil91 = gg.getResults(100000)

    if #hasil91 == 0 then
        gg.alert(" 91 tidak ditemukan!")
        return
    end

    local hasilOffset = {}

    for _, v in ipairs(hasil91) do
        hasilOffset[#hasilOffset + 1] = {
            address = v.address + 0xE0,
            flags = gg.TYPE_DOUBLE
        }
    end

    local input = gg.prompt({
        "Masukkan score yang sedang terlihat:"
    }, {
        "0"
    }, {
        "number"
    })

    if input == nil then
        return
    end

    local scoreDilihat = tonumber(input[1])
    local kandidat = {}

    for _, v in ipairs(gg.getValues(hasilOffset)) do
        if v.value == scoreDilihat then
            kandidat[#kandidat + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE
            }
        end
    end

    if #kandidat == 0 then
        gg.alert(" Score " .. scoreDilihat .. " tidak ditemukan!")
        gg.clearResults()
        return
    end

    savedScore = kandidat[1].address

    gg.clearResults()

    gg.toast(" Score berhasil disimpan!")
end

function editScore()
    if savedScore == nil then
        gg.alert(" Kamu belum menyimpan Score!\n\nGunakan menu Save Score terlebih dahulu.")
        return
    end

    local input = gg.prompt({
        "Masukkan score baru:"
    }, {
        "0"
    }, {
        "number"
    })

    if input == nil then
        return
    end

    gg.setValues({
        {
            address = savedScore,
            flags = gg.TYPE_DOUBLE,
            value = input[1],
            freeze = false
        }
    })

    gg.toast(" Score berhasil diubah menjadi " .. input[1])
    gg.clearResults()
end

function csMenu()
    gg.toast(" Change Score Menu Selected!")
    local pilih = gg.choice({
        " Save Score",
        " Edit Score",
        " Return"
    }, nil, blood() .. "\nChange Score")

    if pilih == nil then
        return
    elseif pilih == 1 then
        saveScore()
    elseif pilih == 2 then
        editScore()
    elseif pilih == 3 then
        return
    end
end

-- ============================================================
-- CUSTOM RECRUIT
-- ============================================================

function cusr()
    gg.clearResults()

    gg.searchNumber("55", gg.TYPE_DOUBLE)
    local hasil55 = gg.getResults(100000)

    if #hasil55 == 0 then
        gg.alert(" 55 tidak ditemukan!")
        return
    end

    local hasilOffset = {}

    for _, v in ipairs(hasil55) do
        hasilOffset[#hasilOffset + 1] = {
            address = v.address - 0x30,
            flags = gg.TYPE_DOUBLE
        }
    end

    local hasil10 = {}

    for _, v in ipairs(gg.getValues(hasilOffset)) do
        if v.value == 10 then
            hasil10[#hasil10 + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE
            }
        end
    end

    if #hasil10 == 0 then
        gg.alert(" 10 tidak ditemukan!")
        gg.clearResults()
        return
    end

    local input = gg.prompt({
        "Mau edit 10 menjadi:"
    }, {
        "4"
    }, {
        "number"
    })

    if input == nil then
        gg.clearResults()
        return
    end

    local edit = {}

    for _, v in ipairs(hasil10) do
        edit[#edit + 1] = {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = input[1]
        }
    end

    gg.setValues(edit)

    gg.toast(" 10 berhasil diubah menjadi " .. input[1])
    gg.clearResults()
end

-- ============================================================
-- SET PLAYER MENU (DUMMY)
-- ============================================================

function spMenu()
    gg.alert(" Nunggu Update, soalnya sering error!")
end
-- ============================================================
-- GAMEPLAY MENU (DUMMY + HIGH FOV + FAST WIN)
-- ============================================================

local dummyActive = false
local dummyAddresses = {}
local fovActive = false
local fovAddresses = {}
local fastWinAktif = false
local fastWinData = {}
local DEFAULT_MEMORY = gg.REGION_C_ALLOC | gg.REGION_OTHER

function restoreMemory()
    gg.setRanges(DEFAULT_MEMORY)
    gg.toast(" Memory restored ke default")
end

-- ============================================================
-- DUMMY ENEMY (ON/OFF TOGGLE)
-- ============================================================

function dummyEnemy()
    if dummyActive then
        gg.toast(" Mematikan Dummy Enemy...")

        local listRevert = {}

        for _, v in ipairs(dummyAddresses) do
            if v and v ~= 0 then
                listRevert[#listRevert + 1] = {
                    address = v,
                    flags = gg.TYPE_DWORD,
                    value = 905969920
                }
            end
        end

        if #listRevert > 0 then
            local ok, err = pcall(function()
                gg.setValues(listRevert)
            end)

            if ok then
                gg.alert(" DUMMY ENEMY DINONAKTIFKAN!")
            else
                gg.alert(" Gagal mematikan!\n\nError: " .. tostring(err))
            end
        end

        dummyActive = false
        dummyAddresses = {}
        cleanup()
        restoreMemory()
        return
    end

    setupMemory()
    cleanup()

    gg.setRanges(gg.REGION_CODE_APP)
    gg.toast(" Memory set ke XA (REGION_CODE_APP)")

    gg.toast(" Mencari Dummy Enemy...")

    gg.searchNumber("905969920", gg.TYPE_DWORD)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert(" Nilai dummy tidak ditemukan!")
        cleanup()
        restoreMemory()
        return
    end

    gg.toast(" Ditemukan " .. #hasil1 .. " hasil untuk dummy")

    local offset1 = {}

    for _, v in ipairs(hasil1) do
        offset1[#offset1 + 1] = {
            address = v.address + 0x4,
            flags = gg.TYPE_DWORD
        }
    end

    gg.loadResults(offset1)
    gg.refineNumber("1384120488", gg.TYPE_DWORD)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert(" Nilai 1384120488 tidak ditemukan!")
        cleanup()
        restoreMemory()
        return
    end

    gg.toast(" Ditemukan " .. #hasil2 .. " hasil")

    local offset2 = {}

    for _, v in ipairs(hasil2) do
        offset2[#offset2 + 1] = {
            address = v.address - 0x4,
            flags = gg.TYPE_DWORD
        }
    end

    gg.loadResults(offset2)
    gg.refineNumber("905969920", gg.TYPE_DWORD)
    local hasilFinal = gg.getResults(100000)

    if #hasilFinal == 0 then
        gg.alert(" Nilai dummy tidak ditemukan!")
        cleanup()
        restoreMemory()
        return
    end

    gg.toast(" Ditemukan " .. #hasilFinal .. " hasil final")

    dummyAddresses = {}
    local listEdit = {}

    for _, v in ipairs(hasilFinal) do
        if v.address and v.address ~= 0 then
            dummyAddresses[#dummyAddresses + 1] = v.address

            listEdit[#listEdit + 1] = {
                address = v.address,
                flags = gg.TYPE_DWORD,
                value = 905969921
            }
        end
    end

    if #listEdit == 0 then
        gg.alert(" Gagal!")
        cleanup()
        restoreMemory()
        return
    end

    local ok, err = pcall(function()
        gg.setValues(listEdit)
    end)

    if ok then
        dummyActive = true
        cleanup()
        restoreMemory()

        gg.alert(" DUMMY ENEMY AKTIF (ON)!\n\n" ..
                 " Klik lagi untuk mematikan (OFF)")
    else
        cleanup()
        restoreMemory()
        dummyAddresses = {}
        gg.alert(" Gagal!\n\nError: " .. tostring(err))
    end
end

-- ============================================================
-- HIGH FOV
-- ============================================================

function highFOV()
    setupMemory()
    cleanup()

    gg.toast(" Mencari High FOV...")

    gg.searchNumber("0.3", gg.TYPE_DOUBLE)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert(" 0.3 tidak ditemukan!")
        cleanup()
        restoreMemory()
        return
    end

    gg.toast(" Ditemukan " .. #hasil1 .. " hasil untuk 0.3")

    local offset1 = {}

    for _, v in ipairs(hasil1) do
        offset1[#offset1 + 1] = {
            address = v.address - 0x1260,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offset1)
    gg.refineNumber("1", gg.TYPE_DOUBLE)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert(" 60 tidak ditemukan di offset -0x1260!")
        cleanup()
        restoreMemory()
        return
    end

    gg.toast(" Ditemukan " .. #hasil2 .. " hasil untuk 60")

    local offset2 = {}

    for _, v in ipairs(hasil2) do
        offset2[#offset2 + 1] = {
            address = v.address + 0x30,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offset2)
    gg.refineNumber("1", gg.TYPE_DOUBLE)
    local hasilFinal = gg.getResults(100000)

    if #hasilFinal == 0 then
        gg.alert(" 1 tidak ditemukan di offset +0x60!")
        cleanup()
        restoreMemory()
        return
    end

    gg.toast(" Ditemukan " .. #hasilFinal .. " hasil final")

    local listEdit = {}

    for _, v in ipairs(hasilFinal) do
        if v.address and v.address ~= 0 then
            listEdit[#listEdit + 1] = {
                address = v.address,
                flags = gg.TYPE_DOUBLE,
                value = 12
            }
        end
    end

    if #listEdit == 0 then
        gg.alert(" Gagal!")
        cleanup()
        restoreMemory()
        return
    end

    local ok, err = pcall(function()
        gg.setValues(listEdit)
    end)

    if ok then
        cleanup()
        restoreMemory()
        gg.alert(" HIGH FOV BERHASIL!\n\n" ..
                 "Nilai diubah: 1  12\n" ..
                 "Jumlah: " .. #listEdit .. " alamat")
    else
        cleanup()
        restoreMemory()
        gg.alert(" Gagal!\n\nError: " .. tostring(err))
    end
end

-- ============================================================
-- FAST WIN (ON/OFF TOGGLE)
-- ============================================================

function fastWin()
    if fastWinAktif then
        if #fastWinData > 0 then
            gg.setValues(fastWinData)
        end

        fastWinData = {}
        fastWinAktif = false

        gg.toast(" FAST WIN OFF")
        return
    end

    setupMemory()
    cleanup()

    gg.toast(" Mencari Fast Win...")

    gg.searchNumber("16000", gg.TYPE_DOUBLE)
    local hasil16000 = gg.getResults(100000)

    if #hasil16000 == 0 then
        gg.alert(" 16000 tidak ditemukan!")
        cleanup()
        return
    end

    local hasilOffset = {}

    for _, v in ipairs(hasil16000) do
        hasilOffset[#hasilOffset + 1] = {
            address = v.address - 1190,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(hasilOffset)
    gg.searchNumber("1573.12", gg.TYPE_DOUBLE)
    local hasil1573 = gg.getResults(100000)

    if #hasil1573 == 0 then
        gg.alert(" 1573.12 tidak ditemukan!")
        cleanup()
        return
    end

    local listEdit = {}

    for _, v in ipairs(hasil1573) do
        fastWinData[#fastWinData + 1] = {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = v.value
        }

        listEdit[#listEdit + 1] = {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = 1550
        }
    end

    gg.setValues(listEdit)

    fastWinAktif = true

    gg.toast(" FAST WIN ON")

    cleanup()
end
--UNLIMITED SKILL

function unlimitedSkill()
    while true do
        local pilih = gg.choice({
            "Unlimited Skill Sanghyeon",
            "Unlimited Skill Sara",
            "↩ Kembali"
        }, nil, "🎮 GAMEPLAY MENU")

        if pilih == nil or pilih == 3 then
            break
        elseif pilih == 1 then
            unlimitedSkillSanghyeon()
        elseif pilih == 2 then
            unlimitedSkillSara()
        elseif pilih == 3 then
            menuUtama()
        end
    end
end
-- ============================================================
-- GAMEPLAY MENU
-- ============================================================

function gameplayMenu()
    while true do
        local pilih = gg.choice({
            "🤖 Dummy Enemy " .. (dummyActive and "✅ ON" or "❌ OFF"),
            "🎯 High FOV",
            "⚡ Fast Win " .. (fastWinAktif and "✅ ON" or "❌ OFF"),
            "✏️ Custom Name Mastery",
            "💪 Unlimited Skill ",
            "↩ Kembali"
        }, nil, "🎮 GAMEPLAY MENU")

        if pilih == nil or pilih == 6 then
            break
        elseif pilih == 1 then
            dummyEnemy()
        elseif pilih == 2 then
            highFOV()
        elseif pilih == 3 then
            fastWin()
        elseif pilih == 4 then
            customNameMastery()
        elseif pilih == 5 then
            unlimitedSkill()
        elseif pilih == 6 then
            menuUtama()
        end
    end
end
-- ============================================================
-- SEARCH & REPLACE TEKS
-- ============================================================

function searchAndReplace()
    setupMemory()
    cleanup()

    local inputCari = gg.prompt({
        " Cari teks:"
    }, {
        ":"
    }, {
        "text"
    })

    if inputCari == nil then
        gg.toast(" Dibatalkan")
        return
    end

    local teksCari = inputCari[1]

    if teksCari == nil or teksCari == "" then
        gg.alert(" Teks tidak boleh kosong!")
        return
    end

    gg.toast(" Mencari: " .. teksCari .. " ...")

    gg.searchNumber(teksCari, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, 0, -1, 0)
    local hasil = gg.getResults(100000)

    if #hasil == 0 then
        gg.alert(" Teks '" .. teksCari .. "' tidak ditemukan!")
        cleanup()
        return
    end

    gg.toast(" Ditemukan " .. #hasil .. " hasil")

    local inputEdit = gg.prompt({
        " Ganti dengan:"
    }, {
        ":"
    }, {
        "text"
    })

    if inputEdit == nil then
        cleanup()
        return
    end

    local teksBaru = inputEdit[1]

    if teksBaru == nil or teksBaru == "" then
        gg.alert(" Teks tidak boleh kosong!")
        cleanup()
        return
    end

    gg.editAll(teksBaru, gg.TYPE_BYTE)

    gg.alert(" BERHASIL!\n\n" ..
             "Teks '" .. teksCari .. "' diganti jadi '" .. teksBaru .. "'\n" ..
             "Jumlah: " .. #hasil .. " alamat")

    gg.processResume()
    cleanup()
end

-- ============================================================
-- MEMORY RANGE MENU
-- ============================================================

function smMenu()
    local pilih = gg.choice({
        " Set Range Android 12- Ca_Alloc",
        " Set Range android 13+ Other",
        " Set Range Ca_Alloc + Other",
        " Return"
    }, nil, blood() .. "\n" .. "Memory Options")

    if pilih == nil then
        return
    elseif pilih == 1 then
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.toast(" Set Range Ca_Alloc Success")
    elseif pilih == 2 then
        gg.setRanges(gg.REGION_OTHER)
        gg.toast(" Set Range Other Success")
    elseif pilih == 3 then
        gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_OTHER)
        gg.toast(" Set Range Ca_Alloc + Other Success")
    elseif pilih == 4 then
        menuUtama()
    end
end
-- ============================================================
-- CUSTOM NAME MASTERY (GANTI TEKS CHAMPION / MASTERY)
-- ============================================================

function customNameMastery()
    -- Set memory range ke CODE_APP
    gg.alert("Wajib menggunakan mastery Champion")
    gg.setRanges(gg.REGION_CODE_APP)

    gg.toast(" Mencari teks mastery default...")

    -- Cari teks "CHAMPION MASTERY" dalam hex
    -- h43 48 41 4D 50 49 4F 4E 00 4D 41 53 54 45 52 59 = "CHAMPION MASTERY"
    gg.searchNumber("h43 48 41 4D 50 49 4F 4E 00 3F 3F 3F 3F 00 55 4E 4B 4E 4F 57 4E", gg.TYPE_BYTE, false, gg.SIGN_EQUAL, 0, -1, 0)
    
    local hasil = gg.getResults(100000)

    if #hasil == 0 then
        gg.alert(" Teks 'CHAMPION MASTERY' tidak ditemukan!")
        gg.clearResults()
        return
    end

    gg.toast(" Ditemukan " .. #hasil .. " hasil")

    -- Input teks baru
    local inputEdit = gg.prompt({
        " Ganti 'CHAMPION MASTERY' dengan:"
    }, {
        ":HANZZ STORE VIP"
    }, {
        "text"
    })

    if inputEdit == nil then
        gg.clearResults()
        return
    end

    local teksBaru = inputEdit[1]

    if teksBaru == nil or teksBaru == "" then
        gg.alert(" Teks tidak boleh kosong!")
        gg.clearResults()
        return
    end

    -- EDIT LANGSUNG
    gg.editAll(teksBaru, gg.TYPE_BYTE)

    gg.alert(" BERHASIL!\n\n" ..
             "Teks 'CHAMPION MASTERY' diganti jadi:\n" ..
             "'" .. teksBaru .. "'\n\n" ..
             " Restart game untuk melihat perubahan!")

    gg.processResume()
    gg.clearResults()
end
-- ============================================================
-- RULES
-- ============================================================

function rlMenu()
    gg.alert("Rules Dari Hanzz :\n1. Dilarang Menjual Script VIP\n\nNote : kalo ketauan ngelanggar key bakal di banned")
    menuUtama()
end
-- ============================================================
-- SHOW FPS MODE
-- ============================================================

function showFpsMode()
    setupMemory()

    gg.toast(" SHOW FPS MODE aktif...")
    gg.clearResults()

    -- ============================================================
    -- STEP 1: Cari nilai 1199715669 (Dword)
    -- ============================================================
    gg.toast(" [STEP 1] Scan nilai 1199715669...")
    gg.searchNumber("1199715669", gg.TYPE_DWORD)
    local hasilScan = gg.getResults(100000)

    if #hasilScan == 0 then
        gg.alert(" Nilai 1199715669 tidak ditemukan!")
        gg.clearResults()
        return
    end

    gg.toast(" [STEP 1] Ditemukan " .. #hasilScan .. " hasil")

    -- ============================================================
    -- STEP 2: Offset +0x8  ubah jadi tipe Double
    -- ============================================================
    local offsetList = {}
    for _, v in ipairs(hasilScan) do
        offsetList[#offsetList + 1] = {
            address = v.address + 0x8,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.toast(" [STEP 2] Offset +0x8 berhasil, ubah ke Double")

    -- ============================================================
    -- STEP 3: Edit jadi 2.00000047684
    -- ============================================================
    local editList = {}
    for _, v in ipairs(offsetList) do
        editList[#editList + 1] = {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = 2.00000047684
        }
    end

    if #editList == 0 then
        gg.alert(" Gagal menyiapkan edit!")
        gg.clearResults()
        return
    end

    local ok, err = pcall(function()
        gg.setValues(editList)
    end)

    if not ok then
        gg.alert(" Gagal edit!\n\n" .. tostring(err))
        gg.clearResults()
        return
    end

    gg.clearResults()

    gg.alert(" SHOW FPS MODE BERHASIL!\n\n" ..
             "Jumlah di-edit: " .. #editList .. "\n" ..
             "Value baru: 2.00000047684\n\n" ..
             " Restart game atau pindah menu!")
end
-- ============================================================
-- FUNGSI V1
-- ============================================================
function autoWinV1()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.toast("Setup Memory Ready✅")

    gg.clearResults()

    gg.searchNumber("-1342087775", gg.TYPE_DWORD)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert("Refine Not Found ❎!")
        gg.clearResults()
        return false
    end

    local offsetList = {}
    for _, v in ipairs(hasil1) do
        offsetList[#offsetList + 1] = {
            address = v.address - 0x2F8,
            flags = gg.TYPE_DWORD
        }
    end

    gg.loadResults(offsetList)
    gg.refineNumber("-788020225", gg.TYPE_DWORD)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert("Refine Not Found ❎!")
        gg.clearResults()
        return false
    end

    local alamatTarget = {}
    for _, v in ipairs(hasil2) do
        alamatTarget[#alamatTarget + 1] = v.address
    end

    local editList = {}
    for _, addr in ipairs(alamatTarget) do
        editList[#editList + 1] = {
            address = addr,
            flags = gg.TYPE_BYTE,
            value = 95
        }
    end

    gg.setValues(editList)
    gg.toast("Berhasil✅")

    local nilaiOffset = {
        [1]  = 0, [2]  = 0, [3]  = -7, [4]  = -88, [5]  = 1,
        [6]  = -128, [7]  = 82, [8]  = 72, [9]  = 12, [10] = 0,
        [11] = -71, [12] = -32, [13] = 3, [14] = 2, [15] = -86,
        [16] = -64, [17] = 3, [18] = 95, [19] = -42
    }

    local semuaEdit = {}
    for _, addr in ipairs(alamatTarget) do
        for i = 1, 19 do
            semuaEdit[#semuaEdit + 1] = {
                address = addr + i,
                flags = gg.TYPE_BYTE,
                value = nilaiOffset[i]
            }
        end
    end

    gg.setValues(semuaEdit)
    gg.clearResults()
    gg.toast(" ✅Selesai!")

    return true
end
-- ============================================================
-- SCORE TEAM V2 - EDIT 12 & 0 (FROZEN)
-- ============================================================
function autoWinV2()
    setupMemory()
    gg.toast("Memory ready")

    gg.clearResults()

    -- ============================================================
    -- STEP 1: Cari 795364 (Dword)
    -- ============================================================
    gg.searchNumber("795364", gg.TYPE_DWORD)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert(" [V2] 795364 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    gg.toast(" [V2] Ditemukan " .. #hasil1 .. " hasil")

    -- ============================================================
    -- STEP 2: Offset -0x90
    -- ============================================================
    local offsetList1 = {}
    for _, v in ipairs(hasil1) do
        offsetList1[#offsetList1 + 1] = {
            address = v.address - 0x90,
            flags = gg.TYPE_DWORD
        }
    end

    gg.loadResults(offsetList1)

    -- ============================================================
    -- STEP 3: Cari lagi 795364 (Dword)
    -- ============================================================
    gg.refineNumber("795364", gg.TYPE_DWORD)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert("Refine Not Found ❎!")
        gg.clearResults()
        return false
    end

    -- ============================================================
    -- STEP 4: Offset +0x120, ubah jadi Double
    -- ============================================================
    local offsetList2 = {}
    for _, v in ipairs(hasil2) do
        offsetList2[#offsetList2 + 1] = {
            address = v.address + 0x120,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetList2)

    -- ============================================================
    -- STEP 5: Cari nilai 0-15
    -- ============================================================
    local nilaiKetemu = nil
    local alamatKetemu = nil

    for nilai = 0, 25 do

        gg.clearResults()
        gg.loadResults(offsetList2)
        gg.refineNumber(tostring(nilai), gg.TYPE_DOUBLE)
        local hasilCari = gg.getResults(100000)

        if #hasilCari > 0 then
            nilaiKetemu = nilai
            alamatKetemu = {}
            for _, v in ipairs(hasilCari) do
                alamatKetemu[#alamatKetemu + 1] = v.address
            end
            break
        end
    end

    if nilaiKetemu == nil then
        gg.alert("Refine Not Found ❎!")
        gg.clearResults()
        return false
    end

    -- ============================================================
    -- STEP 6: Edit jadi 12 + Freeze, terus offset -10 edit 0 + freeze
    -- ============================================================

    local editList = {}

    for _, addr in ipairs(alamatKetemu) do
        -- Offset 0  edit 12 + freeze
        editList[#editList + 1] = {
            address = addr,
            flags = gg.TYPE_DOUBLE,
            value = 12,
            freeze = true
        }

        -- Offset -10  edit 0 + freeze
        editList[#editList + 1] = {
            address = addr - 10,
            flags = gg.TYPE_DOUBLE,
            value = 0,
            freeze = true
        }
    end

    if #editList == 0 then
        gg.alert("Refine Not Found ❎")
        gg.clearResults()
        return false
    end
    
    gg.clearResults()
    gg.searchNumber("16000", gg.TYPE_DOUBLE)
    local hasil16000 = gg.getResults(100000)

    if #hasil16000 == 0 then
        gg.alert(" 16000 tidak ditemukan!")
        cleanup()
        return
    end

    local hasilOffset = {}

    for _, v in ipairs(hasil16000) do
        hasilOffset[#hasilOffset + 1] = {
            address = v.address - 1190,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(hasilOffset)
    gg.searchNumber("1573.12", gg.TYPE_DOUBLE)
    local hasil1573 = gg.getResults(100000)

    if #hasil1573 == 0 then
        gg.alert("Refine Not Found ❎!")
        cleanup()
        return
    end

    local listEdit = {}

    for _, v in ipairs(hasil1573) do
        fastWinData[#fastWinData + 1] = {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = v.value
        }

        listEdit[#listEdit + 1] = {
            address = v.address,
            flags = gg.TYPE_DOUBLE,
            value = 1573.12
        }
    end

    gg.setValues(listEdit)
    gg.setValues(editList)
    gg.addListItems(editList)

    gg.clearResults()

    return true
end
-- ============================================================
-- Score Team: SCORE 1-25
-- ============================================================
function scoreTeam()
    setupMemory()
    gg.toast(" [V2] Memory ready")

    gg.clearResults()

    -- STEP 1: Cari 795364 (Dword)
    gg.searchNumber("795364", gg.TYPE_DWORD)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert("Refine Not Found ❎!")
        gg.clearResults()
        return false
    end

    gg.toast(" [V2] Ditemukan " .. #hasil1 .. " hasil")

    -- STEP 2: Offset -90
    local offsetList1 = {}
    for _, v in ipairs(hasil1) do
        offsetList1[#offsetList1 + 1] = {
            address = v.address - 0x90,
            flags = gg.TYPE_DWORD
        }
    end

    gg.loadResults(offsetList1)

    -- STEP 3: Cari lagi 795364
    gg.refineNumber("795364", gg.TYPE_DWORD)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert("Refine Not Found ❎")
        gg.clearResults()
        return false
    end

    gg.toast(" [V2] Ditemukan " .. #hasil2 .. " hasil")

    -- STEP 4: Offset +0x120, ubah jadi Double
    local offsetList2 = {}
    for _, v in ipairs(hasil2) do
        offsetList2[#offsetList2 + 1] = {
            address = v.address + 0x120,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetList2)

    -- STEP 5: Cari nilai 0-15
    local nilaiKetemu = nil
    local alamatKetemu = nil

    for nilai = 0, 25 do

        gg.clearResults()
        gg.loadResults(offsetList2)
        gg.refineNumber(tostring(nilai), gg.TYPE_DOUBLE)
        local hasilCari = gg.getResults(100000)

        if #hasilCari > 0 then
            nilaiKetemu = nilai
            alamatKetemu = {}
            for _, v in ipairs(hasilCari) do
                alamatKetemu[#alamatKetemu + 1] = v.address
            end
            break
        end
    end

    if nilaiKetemu == nil then
        gg.alert("Refine Not Found ❎!")
        gg.clearResults()
        return false
    end

-- ============================================================
-- STEP 6: PILIH SCORE BARU (0-25)
-- ============================================================
local menuScore = {}
local nilaiScore = {}  --  Simpan nilai asli tiap pilihan

-- Loop dari 0 sampai 25 (26 pilihan)
for i = 0, 25 do
    menuScore[#menuScore + 1] = " Score " .. i
    nilaiScore[#nilaiScore + 1] = i  --  Simpan nilainya
end

menuScore[#menuScore + 1] = " Batal"

local pilihScore = gg.choice(
    menuScore,
    nil,
    "PILIH SCORE BARU (0-25)\n\nNilai asal: " .. nilaiKetemu
)

if pilihScore == nil or pilihScore == #menuScore then
    gg.toast(" Dibatalkan")
    gg.clearResults()
    return false
end

-- Ambil nilai asli dari tabel
local scoreBaru = nilaiScore[pilihScore]  --  FIX: Ambil nilai asli

gg.toast(" Score dipilih: " .. scoreBaru)

    -- ============================================================
    -- STEP 7: Edit jadi score baru + Freeze
    -- ============================================================
    gg.toast(" Edit jadi " .. scoreBaru .. " & freeze...")

    local editList = {}
    for _, addr in ipairs(alamatKetemu) do
        editList[#editList + 1] = {
            address = addr,
            flags = gg.TYPE_DOUBLE,
            value = scoreBaru,
            freeze = true
        }
    end

    gg.setValues(editList)
    gg.addListItems(editList)

    gg.clearResults()

    return true
end
-- ============================================================
-- Score Enemy: SCORE 1-25
-- ============================================================
function scoreEnemy()
    setupMemory()
    gg.toast(" [V2] Memory ready")

    gg.clearResults()

    -- STEP 1: Cari 795364 (Dword)
    gg.searchNumber("795364", gg.TYPE_DWORD)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert(" [V2] 795364 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    -- STEP 2: Offset -90
    local offsetList1 = {}
    for _, v in ipairs(hasil1) do
        offsetList1[#offsetList1 + 1] = {
            address = v.address - 0x90,
            flags = gg.TYPE_DWORD
        }
    end

    gg.loadResults(offsetList1)

    -- STEP 3: Cari lagi 795364
    gg.refineNumber("795364", gg.TYPE_DWORD)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert("Refine Not Found")
        gg.clearResults()
        return false
    end

    -- STEP 4: Offset +0x120, ubah jadi Double
    local offsetList2 = {}
    for _, v in ipairs(hasil2) do
        offsetList2[#offsetList2 + 1] = {
            address = v.address + 0x110,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetList2)

    -- STEP 5: Cari nilai 0-15
    local nilaiKetemu = nil
    local alamatKetemu = nil

    for nilai = 0, 25 do

        gg.clearResults()
        gg.loadResults(offsetList2)
        gg.refineNumber(tostring(nilai), gg.TYPE_DOUBLE)
        local hasilCari = gg.getResults(100000)

        if #hasilCari > 0 then
            nilaiKetemu = nilai
            alamatKetemu = {}
            for _, v in ipairs(hasilCari) do
                alamatKetemu[#alamatKetemu + 1] = v.address
            end
            gg.toast(" Nilai " .. nilai .. " ketemu: " .. #hasilCari .. " hasil")
            break
        end
    end

    if nilaiKetemu == nil then
        gg.alert("Refine Not Found❎")
        gg.clearResults()
        return false
    end

-- ============================================================
-- STEP 6: PILIH SCORE BARU (0-25)
-- ============================================================
local menuScore = {}
local nilaiScore = {}  --  Simpan nilai asli tiap pilihan

-- Loop dari 0 sampai 25 (26 pilihan)
for i = 0, 25 do
    menuScore[#menuScore + 1] = " Score " .. i
    nilaiScore[#nilaiScore + 1] = i  --  Simpan nilainya
end

menuScore[#menuScore + 1] = " Batal"

local pilihScore = gg.choice(
    menuScore,
    nil,
    "PILIH SCORE BARU (0-25)\n\nNilai asal: " .. nilaiKetemu
)

if pilihScore == nil or pilihScore == #menuScore then
    gg.toast(" Dibatalkan")
    gg.clearResults()
    return false
end

-- Ambil nilai asli dari tabel
local scoreBaru = nilaiScore[pilihScore]  --  FIX: Ambil nilai asli

    -- ============================================================
    -- STEP 7: Edit jadi score baru + Freeze
    -- ============================================================

    local editList = {}
    for _, addr in ipairs(alamatKetemu) do
        editList[#editList + 1] = {
            address = addr,
            flags = gg.TYPE_DOUBLE,
            value = scoreBaru,
            freeze = true
        }
    end

    gg.setValues(editList)
    gg.addListItems(editList)

    gg.clearResults()

    return true
end
-- ============================================================
-- FUNGSI GABUNGAN
-- ============================================================
function autoWin()
    local suksesV1 = autoWinV1()
    gg.sleep(1000)
    local suksesV2 = autoWinV2()
    gg.clearResults()
    gg.alert("Berhasil✅")
    gg.clearResults()
end
-- ============================================================
-- FUNGSI Bypass
-- ============================================================
function bypass()
    gg.setRanges(gg.REGION_CODE_APP)
    gg.toast(" [V1] Memory set ke XA")

    gg.clearResults()

    gg.toast(" [V1-1/4] Cari -1342087775...")
    gg.searchNumber("-1342087775", gg.TYPE_DWORD)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert(" [V1] -1342087775 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    gg.toast(" [V1] Ditemukan " .. #hasil1 .. " hasil")

    gg.toast(" [V1-2/4] Offset -0x2F8...")
    local offsetList = {}
    for _, v in ipairs(hasil1) do
        offsetList[#offsetList + 1] = {
            address = v.address - 0x2F8,
            flags = gg.TYPE_DWORD
        }
    end

    gg.loadResults(offsetList)
    gg.refineNumber("-788020225", gg.TYPE_DWORD)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert(" [V1] -788020225 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    gg.toast(" [V1] Ditemukan " .. #hasil2 .. " hasil")

    gg.toast(" [V1-3/4] Edit 95 (Byte)...")
    local alamatTarget = {}
    for _, v in ipairs(hasil2) do
        alamatTarget[#alamatTarget + 1] = v.address
    end

    local editList = {}
    for _, addr in ipairs(alamatTarget) do
        editList[#editList + 1] = {
            address = addr,
            flags = gg.TYPE_BYTE,
            value = 95
        }
    end

    gg.setValues(editList)
    gg.toast(" [V1] Edit 95 berhasil!")

    local nilaiOffset = {
        [1]  = 0, [2]  = 0, [3]  = -7, [4]  = -88, [5]  = 1,
        [6]  = -128, [7]  = 82, [8]  = 72, [9]  = 12, [10] = 0,
        [11] = -71, [12] = -32, [13] = 3, [14] = 2, [15] = -86,
        [16] = -64, [17] = 3, [18] = 95, [19] = -42
    }

    gg.toast(" [V1-4/4] Edit 19 byte...")
    local semuaEdit = {}
    for _, addr in ipairs(alamatTarget) do
        for i = 1, 19 do
            semuaEdit[#semuaEdit + 1] = {
                address = addr + i,
                flags = gg.TYPE_BYTE,
                value = nilaiOffset[i]
            }
        end
    end

    gg.setValues(semuaEdit)
    gg.clearResults()
    gg.toast(" [V1] Selesai!")

    return true
end
-- ============================================================
-- UNLIMITED SKILL SANGHYEON
-- ============================================================
function unlimitedSkillSanghyeon()
    setupMemory()
    gg.toast("✅ [Sanghyeon] Memory ready")

    gg.clearResults()

    -- ============================================================
    -- STEP 1: Cari 1081262080 (Dword)
    -- ============================================================
    gg.searchNumber("1081262080", gg.TYPE_DWORD)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert("❌ 1081262080 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    -- ============================================================
    -- STEP 2: Offset -4, ubah jadi Double
    -- ============================================================

    local offsetList1 = {}
    for _, v in ipairs(hasil1) do
        offsetList1[#offsetList1 + 1] = {
            address = v.address - 0x4,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetList1)

    -- ============================================================
    -- STEP 3: Cari 300 (Double)
    -- ============================================================
    gg.refineNumber("300", gg.TYPE_DOUBLE)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert("❌ 300 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    -- ============================================================
    -- STEP 4: Offset +10, cari 2100
    -- ============================================================

    local offsetList2 = {}
    for _, v in ipairs(hasil2) do
        offsetList2[#offsetList2 + 1] = {
            address = v.address + 0x10,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetList2)
    gg.refineNumber("2100", gg.TYPE_DOUBLE)
    local hasil3 = gg.getResults(100000)

    if #hasil3 == 0 then
        gg.alert("❌ 2100 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    -- ============================================================
    -- STEP 5: Edit & offset
    -- ============================================================

    local alamatTarget = {}
    for _, v in ipairs(hasil3) do
        alamatTarget[#alamatTarget + 1] = v.address
    end

    if #alamatTarget == 0 then
        gg.alert("❌ Gagal ambil alamat!")
        gg.clearResults()
        return false
    end

    local editList = {}

    for _, addr in ipairs(alamatTarget) do
        -- Offset 0 → edit 999999999
        editList[#editList + 1] = {
            address = addr,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset +10 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x10,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset +20 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x20,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset -30 → edit 999999999
        editList[#editList + 1] = {
            address = addr - 0x10,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }
    end

    if #editList == 0 then
        gg.alert("❌ Gagal Mengubah Skill!")
        gg.clearResults()
        return false
    end

    local ok, err = pcall(function()
        gg.setValues(editList)
    end)

    if not ok then
        gg.alert("❌ Gagal edit!\n\nError: ")
        gg.clearResults()
        return false
    end

    gg.clearResults()
    gg.toast("✅ [Sanghyeon] Selesai!")

    gg.alert("✅Login Ulang Untuk Perubahan Skill!!!")
    gg.setVisible(false)
    return true
end

function unlimitedSkillSara()
    setupMemory()
    gg.toast("✅ [Sara] Memory ready")

    gg.clearResults()

    -- ============================================================
    -- STEP 1: Cari 1081262080 (Dword)
    -- ============================================================
    gg.searchNumber("1082556416", gg.TYPE_DWORD)
    local hasil1 = gg.getResults(100000)

    if #hasil1 == 0 then
        gg.alert("❌ 1081262080 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    -- ============================================================
    -- STEP 2: Offset -4, ubah jadi Double
    -- ============================================================

    local offsetList1 = {}
    for _, v in ipairs(hasil1) do
        offsetList1[#offsetList1 + 1] = {
            address = v.address - 0x4,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetList1)

    -- ============================================================
    -- STEP 3: Cari 300 (Double)
    -- ============================================================
    gg.refineNumber("720", gg.TYPE_DOUBLE)
    local hasil2 = gg.getResults(100000)

    if #hasil2 == 0 then
        gg.alert("❌ 300 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    -- ============================================================
    -- STEP 4: Offset +10, cari 2100
    -- ============================================================

    local offsetList2 = {}
    for _, v in ipairs(hasil2) do
        offsetList2[#offsetList2 + 1] = {
            address = v.address + 0x10,
            flags = gg.TYPE_DOUBLE
        }
    end

    gg.loadResults(offsetList2)
    gg.refineNumber("780", gg.TYPE_DOUBLE)
    local hasil3 = gg.getResults(100000)

    if #hasil3 == 0 then
        gg.alert("❌ 2100 tidak ditemukan!")
        gg.clearResults()
        return false
    end

    -- ============================================================
    -- STEP 5: Edit & offset
    -- ============================================================

    local alamatTarget = {}
    for _, v in ipairs(hasil3) do
        alamatTarget[#alamatTarget + 1] = v.address
    end

    if #alamatTarget == 0 then
        gg.alert("❌ Gagal ambil alamat!")
        gg.clearResults()
        return false
    end

    local editList = {}

    for _, addr in ipairs(alamatTarget) do
        -- Offset 0 → edit 999999999
        editList[#editList + 1] = {
            address = addr,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset +10 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x10,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset +20 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x20,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset +30 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x30,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset +40 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x40,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }
        
        -- Offset +50 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x50,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }
        
        -- Offset +60 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x60,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset +70 → edit 999999999
        editList[#editList + 1] = {
            address = addr + 0x70,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }

        -- Offset -30 → edit 999999999
        editList[#editList + 1] = {
            address = addr - 0x10,
            flags = gg.TYPE_DOUBLE,
            value = 99999999999999999
        }
    end

    if #editList == 0 then
        gg.alert("❌ Gagal Mengubah Skill!")
        gg.clearResults()
        return false
    end

    local ok, err = pcall(function()
        gg.setValues(editList)
    end)

    if not ok then
        gg.alert("❌ Gagal edit!\n\nError: ")
        gg.clearResults()
        return false
    end

    gg.clearResults()
    gg.toast("✅ [Sanghyeon] Selesai!")

    gg.alert("✅Login Ulang Untuk Perubahan Skill!!!")
    gg.setVisible(false)
    return true
end
-- ============================================================
-- MENU UTAMA
-- ============================================================
function fiturowner()
    local pilihan = gg.choice({
        " Auto Win Lite",
        " Edit Score Team",
        " Edit Score Enemy",
        " Bypass Anti Cheat",
        " Return"
    }, nil, " AUTO WIN TOOLS \n" .. os.date("%H:%M:%S"))

    if pilihan == nil then
        return
    elseif pilihan == 1 then
        autoWin()
    elseif pilihan == 2 then
        scoreTeam()
    elseif pilihan == 3 then
        scoreEnemy()
    elseif pilihan == 4 then
        bypass()
    elseif pilihan == 5 then
        menuUtama()
    end
end
-- ============================================================
-- EXIT SCRIPT
-- ============================================================

function exitScript()
    gg.alert(" Script berakhir... Terima kasih sudah pakai script By Hanzz~ ")
    os.exit()
end

-- ============================================================
-- CEK EXPIRED
-- ============================================================

function cekExpired()
    local expired = os.time({
        year = 2027,
        month = 9,
        day = 30,
        hour = 12,
        min = 00,
        sec = 00
    })

    if os.time() > expired then
        gg.alert(
            "\n" ..
            "        EXPIRED \n" ..
            "\n\n" ..
            " Script ini sudah expired!\n\n" ..
            " Mohon Hubungi Owner"
        )
        os.exit()
    end
end
-- ============================================================
-- MENU UTAMA (FIX)
-- ============================================================

function menuUtama()
    local pilihan = gg.choice({
        " Character Menu",
        " Mastery Menu",
        " Background in Game",
        " Change Set Player",
        " Change Score",
        " Custom Recruit",
        " Gameplay menu",
        " Volleyball Skin",
        " Rules",
        " Change memory range",
        " Custom UID",
        " SHOW FPS MODE (Developer Menu)",
        " ☠️SECRET FITURE",
        " Exit Script"
    }, nil, blood() .. "\n" .. waktuBold())

    if pilihan == nil then
        return
    elseif pilihan == 1 then
        charMenu()
    elseif pilihan == 2 then
        masteryMenu()
    elseif pilihan == 3 then
        bacMenu()
    elseif pilihan == 4 then
        spMenu()
    elseif pilihan == 5 then
        csMenu()
    elseif pilihan == 6 then
        cusr()
    elseif pilihan == 7 then
        gameplayMenu()
    elseif pilihan == 8 then
        ball()
    elseif pilihan == 9 then
        rlMenu()
    elseif pilihan == 10 then
        smMenu()
    elseif pilihan == 11 then
        searchAndReplace()
    elseif pilihan == 12 then
        showFpsMode()
    elseif pilihan == 13 then
        fiturowner()
    elseif pilihan == 14 then
        exitScript()
    end
end

-- ============================================================
-- STARTUP (FIX - TANPA KOMENTAR GAK GUNA)
-- ============================================================
gg.setVisible(false)

cekExpired()
welcome()
loading()
range()

-- LANGSUNG JALANIN MENU UTAMA
menuUtama()

while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        menuUtama()
    end
    gg.sleep(100)
end

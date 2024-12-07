-- User edited configuration file.
local Environment = require 'ConsentRequiredExtended.Util.Environment'

local _ENV = Environment.PrepareEnvironment(_ENV)

--------- Start editing here ---------

AffectedItems = {
    -- Neurotrauma
    -- "healthscanner", --健康扫描仪 -- whats a tiny bit of radiation damage between friends?
    "bloodanalyzer",      --血液分析仪
    "opium",              --药用鸦片
    "antidama1",          --吗啡
    "antidama2",          --芬太尼
    "antibleeding3",      --抗生素凝膠
    "propofol",           -- 异丙酚
    "mannitol",           -- 甘露醇
    "pressuremeds",       -- 压力药物
    "multiscalpel",       -- 多功能手术刀
    "advscalpel",         -- 手术刀
    "advhemostat",        -- 止血钳
    "advretractors",      -- 皮肤牵引器
    "tweezers",           -- 镊子
    "surgicaldrill",      -- 骨钻
    "surgerysaw",         -- 手术锯
    "organscalpel_liver", -- 器官切割刀：肝脏
    "organscalpel_lungs", -- 器官切割刀：肺
    "organscalpel_kidneys", -- 器官切割刀：肾脏
    "organscalpel_heart", -- 器官切割刀：心脏
    "organscalpel_brain", -- 器官切割刀：大脑
    "emptybloodpack",     -- 空血袋
    "bloodpack",
    "alienblood",         -- 异星血浆
    "tourniquet",         -- 止血带
    "defibrillator",      -- 手动除颤器
    "aed",                -- 智能除颤器
    "bvm",                -- 人工呼吸器
    "antibiotics",        -- 广谱抗生素
    "sulphuricacid",      -- 硫酸
    "divingknife",        -- 潜水刀
    "divingknifedementonite", -- 攝魂潛水刀
    "divingknifehardened", -- 硬化潛水刀
    "crowbar",            -- 潜水刀
    "crowbardementonite", -- 攝魂撬棍
    "crowbarhardened",    -- 硬化撬棍
    "stasisbag",          -- 冷藏袋
    "autocpr",            -- 全自动CPR
    -- NeuroEyes
    "organscalpel_eyes",  -- 器官切割刀：眼睛
    -- blahaj 布罗艾鲨鱼
    -- "blahaj", -- 布罗艾鲨鱼 -- Blahaj never hurt anyone
    -- "blahajplus", -- 大鲨鲨
    "blahajplusplus",   -- 超大鲨鲨
    -- Pharmacy 制药大师
    "custompill",       -- 自制药丸
    "custompill_horsepill", -- 大药丸
    "custompill_tablets", -- 药片
    -- vanilla 原版
    "toyhammer"         -- 玩具锤子
}

--------- Stop editing here ---------

return Environment.Export(_ENV)

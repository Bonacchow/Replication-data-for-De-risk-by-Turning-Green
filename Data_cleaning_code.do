*             ===============================================================
*            				       绿色工厂对成本粘性数据处理
*             ===============================================================

cd "D:\论文\12.绿色工厂对成本粘性"

. clear

. global root= "D:\论文\12.绿色工厂对成本粘性"       
. global Dofiles= "$root\Dofiles"         
. global Rawdata= "$root\Rawdata"
. global Working_data= "$root\Workingdata"
. global Tables= "$root\Tables"
. global Figures= "$root\Figures"
. global SomeDeatils= "$root\SomeDeatils"
. global Blog= "$root\Blog"

. cap !mkdir "$Raw_data"              
. cap  mkdir "$Working_data"
. cap  mkdir "$Tables"          
. cap  mkdir "$Figures"
. cap  mkdir "$Dofiles"          
. cap  mkdir "$root\Paper"
. cap  mkdir "$root\References"
. cap  mkdir "$Rawdata"
. cap  mkdir "$Workingdata"
. cap  mkdir "$Figures" 
. cap  mkdir "$Blog" 

use "$root\控制变量.dta", replace
merge m:1 id year using 绿色工厂数据.dta
drop if _merge==2
drop _merge

**#合并成本粘性
merge m:m id year using $root\Rawdata\成本粘性水平（已缩尾已剔除金融STPT）.dta 
drop if _merge==2
drop _merge
g sticky=成本粘性水平

**#合并ESG数据
merge m:1 id year using ESG2009-2023.dta
drop if _merge!=3
drop _merge

**#合并客户、供应商集中度
merge m:m id year using $root\Rawdata\客户、供应商集中度.dta 
drop if _merge==2
drop _merge

**#合并盈利波动性和现金流波动性
merge m:m id year using $root\Rawdata\盈利波动性和现金流波动性.dta 
drop if _merge==2
drop _merge

**#合并投融资期限错配
merge m:m id year using $root\Rawdata\投融资期限错配.dta 
drop if _merge==2
drop _merge

**#合并研发操纵
merge m:m id year using $root\Rawdata\研发操纵.dta 
drop if _merge==2
drop _merge

**#合并总经理董事长政治关联
merge m:m id year using $root\Rawdata\总经理董事长政治关联.dta 
drop if _merge==2
drop _merge

**#合并绿色生产率
merge m:m id year using $root\Rawdata\greenpro.dta 
drop if _merge==2
drop _merge

**#合并绿色转型
merge m:m id year using $root\Rawdata\绿色化转型.dta 
drop if _merge==2
drop _merge

**#合并持续绿色转型
merge m:m id year using $root\Rawdata\持续绿色创新水平.dta 
drop if _merge==2
drop _merge

**#合并绿色创新效率
merge m:m id year using $root\Rawdata\绿色创新效率.dta 
drop if _merge==2
drop _merge

**#合并绿色补贴
merge m:m id year using $root\Rawdata\envirsub.dta 
drop if _merge==2
drop _merge

**#合并补贴
merge m:m id year using $root\Rawdata\sub.dta 
drop if _merge==2
drop _merge

**#合并信息披露质量
merge m:m id year using $root\Rawdata\disclo.dta, force
drop if _merge==2
drop _merge
gen disc=信息披露质量
bys id: ipolate disc year , gen (disclosure)

**#合并政治关联
merge m:m id year using $root\Rawdata\PC.dta, force
drop if _merge==2
drop _merge
gen connect=PC

**#合并产业政策数量
merge m:m City year using $root\Rawdata\indupo.dta, force
drop if _merge==2
drop _merge
gen funpo=各市功能性产业政策数量
gen selpo=各市选择性产业政策数量
replace funpo=0 if missing(funpo)
replace selpo=0 if missing(selpo)


merge m:m id year using $root\Rawdata\heapoll.dta, force
drop if _merge==2
drop _merge
foreach var in 重污染分组1 重污染分组2 重污染分组3{
	replace `var'=0 if missing(`var')
}

**#剔除
drop if IndusCode=="J66" | IndusCode=="K70" //剔除金融与房地产行业
gen st=1 if strmatch( ShortName ,"*ST*" )
replace st=1 if strmatch( ShortName ,"*PT*" )
drop if st==1 //剔除ST、PT、*ST企业
drop st

bys id:egen MaxListAge=max(listage) //计算企业最大上市年限
drop if MaxListAge<1 //删除最大上市时间不满1年的企业
drop MaxListAge

drop if Lev>=1 //剔除资产负债率大于等于1的样本

bys id:gen action1=year if type=="绿色工厂"
bys id:egen action=min(action1)
replace action=2222 if action==.

bys id:gen did=1 if year>=action
replace did=0 if did==.

gen u=0
replace u=1 if action<2222
gen zcxh=year-action if u>0
drop action action1
replace zcxh=-4 if zcxh<=-4
replace zcxh=4 if zcxh>=4
replace zcxh=. if u==0

tab zcxh,gen(xh)
forvalues i=1/9{
	replace xh`i'=0 if xh`i'==.
}

drop xh4
gen indusxyear=IndusCode*year //生成行业-年度交互项
winsor2 Size Lev ROA1 SOE FirmAge Top1 Indep TobinQ1,replace cuts(1 99)
encode type ,gen (type1)
sort id year
autofill type1, groupby(id) backward
replace type1=0 if missing(type1)

ren City city
merge m:m city year using $root\Rawdata\CV.dta 
drop if _merge==2
drop _merge

*合并其他评级ESG
merge m:m ShortName year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\HuaZhengESG（到2022）.dta", force
drop if _merge==2
drop _merge
merge m:m ShortName year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\CNRDS-ESG.dta", force
drop if _merge==2
drop _merge

ren cnrds_ESG_Score ESGscore_CNRDS
ren ESG_Rank ESGrank_CNRDS
ren HZESG ESGscore_huazheng
sort 综合评级
encode 综合评级,gen(ESGrank_huazheng)

**合并机制变量
merge m:m ShortName year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\CNRDS-慈善、志愿者活动以及社会争议优势.dta", force
drop if _merge==2
drop _merge
foreach var of varlist donation education charity volunteer foreignaid employment localeco {
    ren `var'  `var'1
	gen `var'=real(`var'1)
	}
replace donation=0 if missing(donation)
replace education=0 if missing(education)
replace charity=0 if missing(charity)
replace volunteer=0 if missing(volunteer)
replace foreignaid=0 if missing(foreignaid)
replace employment=0 if missing(employment)
replace localeco=0 if missing(localeco)
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\CNRDS-上市公司绿色专利申请情况.dta", force
drop if _merge==2
drop _merge
ren 当年独立申请的绿色发明数量 greeninvind
ren 当年独立申请的绿色实用新型数量 greenutiind
ren 当年联合申请的绿色发明数量 greeninvco
ren 当年联合申请的绿色实用新型数量 greenutico
duplicates drop id year , force
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\绿色投资者.dta", force
drop if _merge==2
drop _merge
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\环境注意力.dta", force
drop if _merge==2
drop _merge
drop 安全生产_词频 保护_词频 超标_词频 臭氧层_词频 除尘_词频 大气_词频 低碳_词频 二氧化碳_词频 防治_词频 废气_词频 废弃_词频 废水_词频 废物_词频 废渣_词频 粉尘_词频 风能_词频 锅炉_词频 过滤_词频 环保_词频 环境_词频 回收_词频 甲烷_词频 减排_词频 降耗_词频 降解_词频 降噪_词频 节能_词频 节约_词频 净化_词频 可持续发展_词频 可再生_词频 空气_词频 垃圾_词频 浪费_词频 流程再造_词频 绿化_词频 绿色_词频 能耗_词频 能源_词频 排放_词频 排气_词频 排污_词频 破坏_词频 栖息地_词频 清洁_词频 燃料_词频 三废_词频 生态_词频 生物质_词频 水处理_词频 酸性_词频 太阳能_词频 天然气_词频 土壤_词频 脱硫_词频 脱硝_词频 尾气_词频 温室气体_词频 污染_词频 污水_词频 无害_词频 无纸化_词频 物种_词频 消耗_词频 循环_词频 烟尘_词频 烟气_词频 液化气_词频 有毒_词频 有机物_词频 余热_词频 再利_词频 噪声_词频 重金属_词频 自然资源_词频
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\企业绿色治理绩效.dta", force
drop if _merge==2
drop _merge
drop E Q30 H30 max min Pinfo Ninfo p q GGP r
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\企业环境信息披露质量.dta", force
drop if _merge==2
drop _merge
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\高管绿色认知.dta", force
drop if _merge==2
drop _merge
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\融资约束汇总.dta", force
drop if _merge==2
drop _merge
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\全要素生产率K1.dta", force
drop if _merge==2
drop _merge
merge m:m id year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\企业市场价值.dta", force
drop if _merge==2
drop _merge
order id year FC指数 KZ指数 SA指数 WW指数 绿色化转型 绿色科技研发效率 绿色成果转化效率
encode IndusCode, g(induscode)
ren FC指数 FC
ren KZ指数 KZ
ren SA指数 SA
ren WW指数 WW
gen lngreeninv=绿色投资者对数
gen envirw=环境注意力总词频
gen envirhon=环保荣誉或奖励
gen envirill=环境违法事件
gen iso=是否通过ISO14001认证
gen greenkn=绿色认知总词频
gen industr=产业结构高级化
gen govinterv=政府干预程度
gen fiscal=财政分权度
gen greenpro=企业绿色全要素生产率
gen greenchan=绿色技术效率变化指数
gen greenprocee=绿色技术进步变化指数
gen greentrans=绿色化转型
gen greeninvent=绿色科技研发效率
gen inventtrans=绿色成果转化效率
local n=1
foreach var of varlist 盈利波动性*{
	gen earnvol`n'=`var'*1000
	local n=`n'+1
}
local n=1
foreach var of varlist 现金流波动性*{
	gen cashvol`n'=`var'*1000
	local n=`n'+1
}

*政策干扰
merge m:m CityCode year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\lowcarboncity.dta", force
drop if _merge==2
drop _merge

merge m:m CityCode year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\greenfinance.dta", force
drop if _merge==2
drop _merge

merge m:m CityCode year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\carbontrade.dta", force
drop if _merge==2
drop _merge

merge m:m CityCode year using "D:\论文\12.绿色工厂对成本粘性\Rawdata\newen.dta", force
drop if _merge==2
drop _merge
g lowcarbon=低碳城市试点
g carbontop=碳达峰试点
g greenfin=绿色金融改革创新试验区
g carbontr=碳排放交易试点
g ne=real(新能源示范城市)
foreach ab of varlist lowcarbon carbontop greenfin carbontr ne{
	replace `ab'=0 if missing(`ab')
}
duplicates drop id year, force

save "D:\论文\12.绿色工厂对成本粘性\Workingdata\basic.dta", replace
save "D:\论文\12.绿色工厂对成本粘性\Workingdata\basic_heterogeneity.dta", replace


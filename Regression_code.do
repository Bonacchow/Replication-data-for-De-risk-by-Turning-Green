*             ======================================================
*            						 绿色工厂回归
*                         环境规制、企业转型升级以及风险能力
*             ======================================================
**#基准设定
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

use "$root\Workingdata\basic.dta",replace

sort id year
set scheme stsj 
global X="Size Lev  SOE FirmAge Top1 Indep TobinQ1 Growth INST Sboard"
global Z="ListAge"/*PE3 PCF3 PB NetProfit  INST BM1*/
foreach var in $X{
	drop if missing(`var')
}
drop if missing(did)
drop if missing(earnvol1)&missing(earnvol2)&missing(earnvol3)
{
	program define myprogramsti
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

use "$root\Workingdata\basic.dta",replace

sort id year
set scheme stsj 
global X="Size Lev  SOE FirmAge Top1 Indep TobinQ1 Growth INST Sboard"
global Z="ListAge"/*PE3 PCF3 PB NetProfit  INST BM1*/
foreach var in $X{
	drop if missing(`var')
}
drop if missing(did)
drop if missing(earnvol1)&missing(earnvol2)&missing(earnvol3)
	end
}
foreach var in $X{
	drop if missing(`var')
}
drop if missing(did)
drop if missing(earnvol1)&missing(earnvol2)&missing(earnvol3)
**#描述性统计
{
logout, save ("描述性统计") word replace: tabstat earnvol1 earnvol2 earnvol3 did $X ,s(N mean sd min median max) c(s)
}

**#基准回归
{
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3 {
	reghdfe `var'  did, absorb(year id) vce(cluster id)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store BASE`n'
    local n=`n'+1
}
local n=4
foreach var of varlist earnvol1 earnvol2 earnvol3 {
	reghdfe `var'  did $X, absorb(year id) vce(cluster id)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store BASE`n'
    local n=`n'+1
}

esttab BASE*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.0f))
esttab BASE* using $root\Tables\baseline1.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.0f))
drop _est_BASE*
}

**#稳健性检验
**##平行趋势检验
**###方法一
foreach var of varlist earnvol1 earnvol2 earnvol3  {
	reghdfe `var' xh* $X ,a(year id) vce(cl id)
coefplot, baselevels ///
keep(xh*) ///
vertical ///转置图形
 yline(0) ///加入y=0这条虚线
xline(4, lwidth(vthin) lpattern(shortdash) ) ///加入x=0垂直虚线
ylabel(,labsize(*0.75)) xlabel(,labsize(*0.75)) ///横纵坐标轴大小
ytitle("Dynamic effect of policy", size(small)) ///加入Y轴名称,大小small
xtitle("Relative policy timing", size(small)) ///加入X轴名称，大小small 
addplot(line @b @at) ///增加点之间的连线
ciopts(lpattern(dash) recast(rcap) msize(medium)) ///CI为虚线上下封口
scheme(stsj) ///
levels(90) ///
title("`var'") ///
coeflabels(xh1="-4" xh2="-3" xh3="-2" xh5="0" xh6="1" xh7="2" xh8="3" xh9="4")
graph save $root\平行趋势`var'.gph, replace 
graph export $root\平行趋势`var'.png, width(2400) replace 
}

graph combine 平行趋势earnvol1.gph 平行趋势earnvol2.gph 平行趋势earnvol3.gph , graphregion(color(white)) plotregion(color(white))  ysize(1) xsize(1.6)
graph export  $root\Figures\平行趋势1.png, width(2400) replace


**###方法二：event study
sort id year 
by id:gen _year =year
replace _year=. if type1!=1
carryforward _year, replace
gen timetotreat=year-_year

foreach var of varlist earnvol1 earnvol2 earnvol3 {
	eventdd `var' $X , timevar(timetotreat)  method(hdfe, absorb(id year) cluster(id)) baseline(0) lags(6) leads(4) noline accum   graph_op(  ytitle("Coefficient",orientation(horizontal) ) c(l) xtitle("Relative policy timing") xline(0,lwidth(vthin) lpattern(dash) )  title("`var'") )

	graph save $root\event`var'.gph, replace 
	graph export $root\event`var'.png, replace 

}

graph combine event`var'.gph, graphregion(color(white)) plotregion(color(white)) ysize(1) xsize(2)
graph export  $root\Figures\eventdd.png, width(2400) replace

**##安慰剂检验
**placebo1
local n=4
foreach var of varlist earnvol1 earnvol2 earnvol3 {
	duplicates drop id year, force
	xtset id year
	didplacebo BASE`n', treatvar(did) pbou rep(500) seed(10000) 
	graph save $root\安慰剂检验`n'.gph, replace title("`var'")
	graph export $root\安慰剂检验`n'.png, replace title("`var'")
	local n=`n'+1
}
 graph combine 安慰剂检验4.gph 安慰剂检验5.gph 安慰剂检验6.gph, graphregion(color(white)) plotregion(color(white)) ysize(4) xsize(6.5)
graph export  $root\Figures\安慰剂检验一.png, width(2400) replace

**##更改固定效应和聚类
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3 {
	reghdfe `var'  did $X, absorb(year id) cl(induscode)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store FE`n'
    local n=`n'+1
}
local n=4
foreach var of varlist earnvol1 earnvol2 earnvol3 {
	reghdfe `var'  did $X, absorb(year id) cl(CityCode)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store FE`n'
    local n=`n'+1
}
local n=7
foreach var of varlist earnvol1 earnvol2 earnvol3 {
	reghdfe `var'  did $X, absorb(id year) cl(ProCode)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store FE`n'
    local n=`n'+1
}

esttab FE*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s(FirmFE YearFE r2_a N , fmt(%3s %6.4f %6.4f %9.0f))
esttab FE* using $root\Tables\FE.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s(FirmFE YearFE r2_a N, fmt(%3s %6.4f %6.4f %9.0f))

**##使用新被解释变量
local n=1
foreach var of varlist earnvol4 earnvol5 earnvol6 {
	reghdfe `var'  did $X, absorb(year id) cl(id)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store ED`n'
    local n=`n'+1
}
local n=4
foreach var of varlist earnvol7 earnvol8 earnvol9 {
	reghdfe `var'  did $X, absorb(year id) cl(id)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store ED`n'
    local n=`n'+1
}
local n=7
foreach var of varlist earnvol10 earnvol11 earnvol12 {
	reghdfe `var'  did $X, absorb(id year) cl(id)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store ED`n'
    local n=`n'+1
}

esttab ED*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s(FirmFE YearFE r2_a N , fmt(%3s %6.4f %6.4f %9.2f))
esttab ED* using $root\Tables\ED.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s(FirmFE YearFE r2_a N, fmt(%3s %6.4f  %9.2f %9.0f))

**##异质性处理效应下的稳健估计量

**###堆叠did
qui myprogramsti
xtset id year
stackdid earnvol1 did $X , tr(did) group(id) w(-6 6) absorb(id year) cluster(id)
estimate store STA1
qui myprogramsti
xtset id year
stackdid earnvol2 did $X , tr(did) group(id) w(-6 6) absorb(id year) cluster(id)
estimate store STA2
qui myprogramsti
xtset id year
stackdid earnvol3 did $X , tr(did) group(id) w(-6 6) absorb(id year) cluster(id)
estimate store STA3
esttab STA*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s(FirmFE YearFE r2_a N , fmt(%3s %6.4f %6.4f %9.2f)) keep(did $X)
esttab STA* using $root\Tables\STA.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s(FirmFE YearFE r2_a N, fmt(%3s %6.4f %6.4f %9.2f)) keep(did $X)

**##DID multiplegt
	qui myprogramsti
did_multiplegt_dyn earnvol1 id year did , cluster(id) effects(5) placebo(5) controls($X) effects_equal  trends_nonparam(year)  by_path(1)
estimate store PLE1
graph save multiplegt1.gph, replace
	qui myprogramsti
did_multiplegt_dyn earnvol4 id year did , cluster(id) effects(5) placebo(5) controls($X) effects_equal  trends_nonparam(year)  by_path(1)
estimate store PLE2
graph save multiplegt2.gph, replace
	qui myprogramsti
did_multiplegt_dyn earnvol3 id year did , cluster(id) effects(5) placebo(5) controls($X) effects_equal  trends_nonparam(year)  by_path(1)
estimate store PLE3
graph save multiplegt3.gph, replace
esttab PLE*, replace   compress nogap star(* 0.1 ** 0.05 *** 0.01) s(FirmFE YearFE Effect_ℓ N_switchers_effect_ℓ se_effect_ℓ p_equality_effects N , fmt(%3s %6.4f %6.4f %9.2f)) 
esttab PLE* using $root\Tables\PLE.rtf,replace   compress nogap star(* 0.1 ** 0.05 *** 0.01)  s(FirmFE YearFE Effect_ℓ N_switchers_effect_ℓ se_effect_ℓ p_equality_effects N, fmt(%3s %6.4f %6.4f %9.2f)) 
 graph combine multiplegt1.gph multiplegt2.gph multiplegt3.gph, graphregion(color(white)) plotregion(color(white)) ysize(2) xsize(2)
graph export  $root\Figures\did_multiplegt_dyn.png, width(2400) replace

**##eventstudyinteract
qui myprogramsti
sort id year 
by id:gen _year =year
replace _year=. if type1!=1
carryforward _year, replace
gen timetotreat=year-_year
bys id:egen minyear=min(year) if did==1
ren minyear firsttreat
bys id year: egen ever_treated = max(did)
gen nevert = (ever_treated == 0)
drop ever_treated


local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	eventstudyinteract `var' xh* ,absorb(id year) cohort(firsttreat) control_cohort(nevert) covariates($X) vce(cl id)
	estimate store INTER`n'
	qui esgraphii
	graph save esi`n'.gph, replace
	local n=`n'+1
}
esttab INTER*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab INTER* using $root\Tables\eventstudyinteract.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))

graph combine esi1.gph esi2.gph esi3.gph, graphregion(color(white)) plotregion(color(white)) ysize(1) xsize(2)
graph export  $root\Figures\eventstudyinteract.png, width(2400) replace

    

**##因果识别问题：RA-IPWRA(falsed)
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3 {
	reghdfe `var' did $X ,a(year id) vce(cl id)
	teffects ra (`var' $X ) ( did ), vce(cl id) ate/*要求命令报告潜在ATE*/
	estimate store TE`n'
	local n=`n'+1
	teffects ipw (`var' ) (did $X, probit), vce(cl id) ate
	estimate store TE`n'
	local n=`n'+1
	teffects aipw (`var') (did $X, probit), vce(cl id) ate aequations
	estimate store TE`n'
	local n=`n'+1
}

esttab TE*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab TE* using $root\Tables\TE.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))

**##排除其他政策干扰
local n=1
foreach var of varlist lowcarbon carbontop greenfin carbontr ne{
	reghdfe earnvol1 did $X `var' ,a(year id) vce(cl id)
	estimate store POFC`n'
	local n=`n'+1
	reghdfe earnvol2 did $X `var' ,a(year id) vce(cl id)
	estimate store POFC`n'
	local n=`n'+1
	reghdfe earnvol3 did $X `var' ,a(year id) vce(cl id)
	estimate store POFC`n'
	local n=`n'+1
	}
esttab POFC*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab POFC* using $root\Tables\POFC.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))


**##样本非随机分配问题：PSM
{
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	use "$root\Workingdata\basic.dta",replace

	sort id year
	set scheme stsj 
	global X="Size Lev ROA1 SOE FirmAge Top1 Indep TobinQ1"
	global Z="PE3 PCF3 PB NetProfit ListAge INST BM1"
	***
	egen `var'mean=mean(`var')
	gen treat=0
	replace treat=1 if `var'>`var'mean
	***一对三
	psmatch2 treat $X  , outcome(`var') neighbor(3) ate ties logit common
	pstest $X ,both graph
	reghdfe `var' did $X  if _weight!=., a(id year) cluster(id)
	estimate store PSM`n'
	local n=`n'+1
	***卡尺
	sum _pscore
	dis 0.25 * r(sd)
	psmatch2 treat $X , outcome(`var') n(3) cal(0.01) ate ties logit common 
	pstest $X ,both graph
	reghdfe `var' did  $X  if _weight!=., a(id year) cluster(id)
	estimate store PSM`n'
	local n=`n'+1
	***半径
	psmatch2 treat $X, outcome(`var') radius cal(0.01) ate ties logit common 
	pstest $X ,both graph
	reghdfe `var' did  $X  if _weight!=., a(id year) cluster(id)
	estimate store PSM`n'
	local n=`n'+1
	***核匹配
	psmatch2 treat $X, outcome(`var') kernel ate ties logit common 
	pstest $X ,both graph
	reghdfe `var' did  $X  if _weight!=., a(id year) cluster(id)
	estimate store PSM`n'
	local n=`n'+1
	***局部线性回归
	psmatch2 treat $X, outcome(`var') llr ate ties logit common 
	pstest $X ,both graph
	reghdfe `var' did  $X  if _weight!=., a(id year) cluster(id)
	estimate store PSM`n'
	local n=`n'+1
	***马氏匹配
	psmatch2 treat , outcome(`var') mahal($X) n(3) ai(3) ate
	pstest $X ,both graph
	reghdfe `var' did $X  if _weight!=., a(id year) cluster(id)
	estimate store PSM`n'
	local n=`n'+1
	esttab PSM*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( r2_a  N, fmt(%3s %6.4f %6.4f %12.0fc ))
	esttab PSM* using $root\Tables\PSM`var'.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( r2_a  N, fmt(%3s %6.4f %6.4f %12.0fc ))

}
}

**##样本选择偏差问题：heckman (falsed)
{
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	duplicates drop id year, force
	xtset id year
	heckprobit `var' did $X, sel(type1=$X) vce(cl id)  nocnsr
	estimates store HECK`n'
	local n=`n'+1
}
	esttab HECK*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( r2_a lambda selambda sigma chi2 chi2_c p p_c rho N, fmt(%3s %6.4f %6.4f %9.2f))
	esttab HECK* using $root\Tables\HECK.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( r2_a lambda selambda sigma chi2 chi2_c p p_c rho N, fmt(%3s %6.4f %6.4f %9.2f))
}

**##模型选择问题
**###probit
{
	local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	probit `var' did , vce(cl id) 
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store PROBIT`n'
	local n=`n'+1
	probit `var' did  $X, vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store PROBIT`n'
	local n=`n'+1
}

esttab PROBIT*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f)) keep(did $X)
esttab PROBIT* using $root\Tables\PROBIT.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f)) keep(did $X)
}
**###ppml
{
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	ppmlhdfe `var' did , a(id year, save) vce(cl id) nolog
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store PPML`n'
	local n=`n'+1
	ppmlhdfe `var' did $X , a(id year, save) vce(cl id) nolog
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store PPML`n'
	local n=`n'+1
}

esttab PPML*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f)) keep(did $X)
esttab PPML* using $root\Tables\PPML.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f)) keep(did $X)
}
**###nbreg
duplicates drop id year , force
xtset id year
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	xtnbreg `var' did, fe 
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store NBREG`n'
	local n=`n'+1
	xtnbreg `var' did $X , fe 	
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store NBREG`n'
	local n=`n'+1
}

esttab NBREG*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f)) keep(did $X)
esttab NBREG* using $root\Tables\NBREG.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f)) keep(did $X)

**##两阶段did
did2s

**##内生性问题：处理效应模型
{
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3 {
	etregress `var' did, treat(did=$X $Z ) vce(cl id)
	estimates store ET`n'
	local n=`n'+1
	etregress_fixedrho `var' did, treat(did=$X $Z ) vce(cl id) rho(0.5) 
	estimates store ET`n'
	local n=`n'+1
}
esttab ET*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE lambda r2_a  N, fmt(%3s %6.4f %6.4f %9.2f)) 
esttab ET* using $root\Tables\ET.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE lambda r2_a  N, fmt(%3s %6.4f %6.4f %9.2f)) 
}
foreach var of varlist $X{
	gen `var'cross=`var'##i.year
}



**#机制分析(调节效应模型)
local n=1
foreach var of varlist FC KZ {
	reghdfe `var' did lngreeninv did##c.lngreeninv $X, ab(id year) cl(id)
	estadd local FirmFE "YES"
    estadd local YearFE "YES"
	estimates store AD`n'
	local n=`n'+1
	reghdfe `var' did envirw did##c.envirw $X, ab(id year) cl(id)
	estadd local FirmFE "YES"
    estadd local YearFE "YES"
	estimates store AD`n'
	local n=`n'+1
	reghdfe `var' did envirhon did##c.envirhon $X, ab(id year) cl(id)
	estadd local FirmFE "YES"
    estadd local YearFE "YES"
	estimates store AD`n'
	local n=`n'+1
	reghdfe `var' did envirill did##c.envirill $X, ab(id year) cl(id)
	estadd local FirmFE "YES"
    estadd local YearFE "YES"
	estimates store AD`n'
	local n=`n'+1
	reghdfe `var' did iso did##c.iso $X, ab(id year) cl(id)
	estadd local FirmFE "YES"
    estadd local YearFE "YES"
	estimates store AD`n'
	local n=`n'+1
	reghdfe `var' did greenkn did##c.greenkn $X, ab(id year) cl(id)
	estadd local FirmFE "YES"
    estadd local YearFE "YES"
	estimates store AD`n'
	local n=`n'+1
	
}
	esttab AD*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
	esttab AD* using $root\Tables\AD.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s(FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
	

**#机制分析（X对M）
foreach var of varlist lngreeninv envirw envirhon iso greenkn disclosure{
	reghdfe `var' did $X ,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store MECC`n'
	local n=`n'+1
}
esttab MECC*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab MECC* using $root\Tables\MECC.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))


**##行业溢出效应
sort id year
bys induscode year: egen indusfc=mean(FC)
bys induscode year: egen induskz=mean(KZ)
bys CityCode year: egen cityfc=mean(FC)
bys CityCode year: egen citykz=mean(KZ)

xtset id year
reghdfe FC did $X indusfc, ab(id year) cl(id)
estimate store INDU1
reghdfe KZ did $X induskz, ab(id year) cl(id)
estimate store INDU2
reghdfe FC did $X l.indusfc, ab(id year) cl(id)
estimate store INDU3
reghdfe KZ did $X l.induskz, ab(id year) cl(id)
estimate store INDU4
reghdfe FC did $X cityfc, ab(id year) cl(id)
estimate store INDU5
reghdfe KZ did $X citykz, ab(id year) cl(id)
estimate store INDU6
reghdfe FC did $X l.cityfc, ab(id year) cl(id)
estimate store INDU7
reghdfe KZ did $X l.citykz, ab(id year) cl(id)
estimate store INDU8

esttab INDU*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s(FirmFE YearFE r2_a N , fmt(%3s %6.4f %6.4f %9.2f))
esttab INDU* using $root\Tables\INDU.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did indusfc induskz cityfc citykz l.indusfc l.induskz l.cityfc l.citykz) s(FirmFE YearFE r2_a N, fmt(%3s %6.4f %6.4f %9.0f))

**#异质性
**##重污染行业
foreach var in  重污染分组2 重污染分组3{
	reghdfe FC did $X if `var'==0
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store POLLINN`n'
	local n=`n'+1
	reghdfe FC did $X if `var'==1
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store POLLINN`n'
	local n=`n'+1
}
esttab POLLINN*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.0f))
esttab POLLINN* using $root\Tables\POLLINN.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.0f))
**##全要素生产率异质性
egen TFPmean=mean(TFP_OLS)
gen tfp=0
replace tfp=1 if TFPmean<TFP_OLS
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	reghdfe `var' did $X if tfp==0,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store TFP`n'
	local n=`n'+1
	reghdfe `var' did $X if tfp==1,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store TFP`n'
	local n=`n'+1
}

esttab TFP*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab TFP* using $root\Tables\TFP.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))

**##企业市值异质性
egen valuemean=mean(市值A)
gen value=0
replace value=1 if valuemean<市值B
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	reghdfe `var' did $X if value==0,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store VAL`n'
	local n=`n'+1
	reghdfe `var' did $X if value==1,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store VAL`n'
	local n=`n'+1
}

esttab VAL*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab VAL* using $root\Tables\VALU.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))

**##ESG异质性
egen esgmean=mean(ESG)
gen esg=0
replace esg=1 if esgmean<ESG
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	reghdfe `var' did $X if esg==0,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store ESG`n'
	local n=`n'+1
	reghdfe `var' did $X if esg==1,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store ESG`n'
	local n=`n'+1
}

esttab ESG*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab ESG* using $root\Tables\ESG.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))

**##工业固废物产生量异质性
egen indpmean=mean(工业固废物产生量)
gen indp=0
replace indp=1 if indpmean<工业固废物产生量
local n=1
foreach var of varlist earnvol1 earnvol2 earnvol3{
	reghdfe `var' did $X if indp==0,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store INDP`n'
	local n=`n'+1
	reghdfe `var' did $X if indp==1,a(year id) vce(cl id)
	estadd local FirmFE "YES"
	estadd local YearFE "YES"
	estimates store INDP`n'
	local n=`n'+1
}

esttab INDP*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab INDP* using $root\Tables\INDP.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))


**#MTE分析
qui myprogramsti
**##描述性统计
{
desctable $X, filename(MTEdesc) stats(n mean sd min max )
**##制图
set scheme stsj 
global XX=" lngreeninv envirw envirhon iso greenkn "
 dgraph $X, by(type1) echo
 }
**##MTE分析 greenpro greenchan  greentrans greeninvent inventtrans
mtefe earnvol1  $X industr govinterv fiscal connect funpo selpo (type1= greenpro greenchan  greentrans greeninvent inventtrans ) /*参数标准化局部工具变量估计*/
estimates store MTE1

mtefe earnvol2 did $X industr govinterv fiscal connect funpo selpo (type1= greenpro greenchan  greentrans greeninvent inventtrans ) /*参数标准化局部工具变量估计*/
estimates store MTE2

mtefe earnvol3 did $X industr govinterv fiscal connect funpo selpo (type1= greenpro greenchan  greentrans greeninvent inventtrans ) /*参数标准化局部工具变量估计*/
estimates store MTE3

mtefeplot MTE1, late memory /*带有局部平均处理效应权重的 MTE 结果对比*/
mtefeplot MTE2, late memory /*带有局部平均处理效应权重的 MTE 结果对比*/
mtefeplot MTE3, late memory /*带有局部平均处理效应权重的 MTE 结果对比*/

esttab MTE*, replace b(3) se(3) s(N  p_U p_X, fmt(%3s %6.4f %6.4f %9.2f)) compress nogap star(* 0.1 ** 0.05 *** 0.01)  
esttab MTE* using $root\Tables\MTE1.rtf,replace b(3) se(3) s(N p_U p_X, fmt(%3s %6.4f %6.4f %9.2f)) compress nogap star(* 0.1 ** 0.05 *** 0.01) order(type1)






local n=1
foreach var of varlist 现金流波动性1 现金流波动性2 现金流波动性3 {
	reghdfe `var'  did  $X, absorb(year id) cl(id)
    estadd local FirmFE "YES"
    estadd local YearFE "YES"
    estimates store BASE`n'
    local n=`n'+1
}

esttab BASE*, replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01) order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
esttab BASE* using $root\Tables\baseline1.rtf,replace b(3) se(3)  compress nogap star(* 0.1 ** 0.05 *** 0.01)  order(did) s( FirmFE YearFE r2_a  N, fmt(%3s %6.4f %6.4f %9.2f))
drop _est_BASE*



**#program define esgraphi

program drop esgraphii 
program define esgraphii 
set scheme stsj
	// 保存系数和标准误
	matrix C = e(b_iw)
	mata st_matrix("A",sqrt(diagonal(st_matrix("e(V_iw)"))))
	matrix C = C \ A'

	// 创建一个新的矩阵来存储非零系数
	matrix D = J(2, colsof(C), 0)
	local colnames : colfullnames C
	local newcolnames ""

	// 遍历原始矩阵，只保留非零系数
	local col = 1
	forvalues i = 1/`=colsof(C)' {
		if (C[1,`i'] != 0) {
			matrix D[1,`col'] = C[1,`i']
			matrix D[2,`col'] = C[2,`i']
			local oldname : word `i' of `colnames'
			// 提取zcxh后的数字并减去5（假设zcxh5是第一个系数）
			local num = substr("`oldname'", 3, .)
			local newnum = `num' - 5
			local newcolnames `newcolnames' `newnum'
			local ++col
		}
	}

	// 调整矩阵D的大小以匹配实际的非零系数数量
	matrix D = D[1..2, 1..`=`col'-1']

	// 设置新的列名
	matrix colnames D = `newcolnames'

	// 绘图
	coefplot matrix(D[1]), se(D[2]) ///
		ciopts(recast(rcap)) ///
				xlabel(-20(4)12) ///
		xtitle("Coefficient") ///
		ytitle("Relative Policy Time") ///

		end



























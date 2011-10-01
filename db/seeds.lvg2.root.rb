
o0 = Option.create!(
  :name => 'Concerning the length of time a voter must reside in Washington to vote for president and vice president.',
  :short_name => 'Voting',
  :description => 'The legislature has proposed a constitutional amendment on repealing article VI, section 1A, of the Washington Constitution. \n\nThis amendment would remove an inoperative provision from the state constitution regarding the length of time a voter must reside in Washington to vote for president and vice-president.',
  :domain => 'State of Washington',
  :domain_short => 'state',
  :url => 'http://wei.secstate.wa.gov/osos/en/PreviousElections/2011/general/Documents/8205%20complete%20text.pdf',
  :category => 'Senate Joint Resolution',
  :designator => '8205'
)

o1 = Option.create!(
  :name => 'Concerning the budget stabilization account maintained in the state treasury.',
  :short_name => 'Budget',
  :description => 'he legislature has proposed a constitutional amendment on the budget stabilization account maintained in the state treasury. \n\nThis amendment would require the legislature to transfer additional moneys to the budget stabilization account in each fiscal biennium in which the state has received "extraordinary revenue growth", as defined, with certain limitations.',
  :domain => 'State of Washington',
  :domain_short => 'state',
  :url => 'http://wei.secstate.wa.gov/osos/en/PreviousElections/2011/general/Documents/8206%20complete%20text.pdf',
  :category => 'Senate Joint Resolution',
  :designator => '8206'
)

o2 = Option.create!(
  :name => 'Concerning state expenditures on transportation.',
  :short_name => 'Transportation ',
  :description => 'Initiative Measure No. 1125 concerns state expenditures on transportation. \n\nThis measure would prohibit the use of motor vehicle fund revenue and vehicle toll revenue for non-transportation purposes, and require that road and bridge tolls be set by the legislature and be project-specific.',
  :domain => 'State of Washington',
  :domain_short => 'state',
  :url => 'http://wei.secstate.wa.gov/osos/en/PreviousElections/2011/general/Documents/1125%20Full%20Text%20for%20VP.pdf',
  :category => 'Initiative',
  :designator => '1125'
)

o3 = Option.create!(
  :name => 'Concerning long-term care workers and services for elderly and disabled people.',
  :short_name => 'Care workers',
  :description => 'Initiative Measure No. 1163 concerns long-term care workers and services for elderly and disabled people. \n\nThis measure would reinstate background checks, training, and other requirements for long-term care workers and providers, if amended in 2011; and address financial accountability and administrative expenses of the long-term in-home care program.',
  :domain => 'State of Washington',
  :domain_short => 'state',
  :url => 'http://wei.secstate.wa.gov/osos/en/PreviousElections/2011/general/Documents/1163%20Full%20Text%20for%20VP.pdf',
  :category => 'Initiative',
  :designator => '1163'
)

o4 = Option.create!(
  :name => 'Concerning liquor: beer, wine, and spirits (hard liquor).',
  :short_name => 'Liquor',
  :description => 'Initiative Measure No. 1183 concerns liquor: beer, wine, and spirits (hard liquor). \n\nThis measure would close state liquor stores and sell their assets; license private parties to sell and distribute spirits; set license fees based on sales; regulate licensees; and change regulation of wine distribution.',
  :domain => 'State of Washington',
  :domain_short => 'state',
  :url => 'http://wei.secstate.wa.gov/osos/en/PreviousElections/2011/general/Documents/1183%20Full%20Text%20for%20VP.pdf',
  :category => 'Initiative',
  :designator => '1183'
)

o5 = Option.create!(
  :name => 'Levy for Parks and Recreation Operations and Capital Improvements',
  :short_name => 'Parks Levy',
  :description => 'The City of Connell Council adopted Ordinance No. 898 asking voters to increase property taxes to finance parks and recreation operations and facility improvements. This proposition would increase the Citys regular property tax levy by $0.40 per $1,000 over the current levy of assessed valuation for collection beginning in 2012 and use the 2012 levy amount to recalculate subsequent levy limits. s regular property tax levy by $0.40 per $1,000 over the current levy of assessed valuation for collection beginning in 2012 and use the 2012 levy amount to recalculate subsequent levy limits. ',
  :domain => 'City of Connell',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z0 = DomainMap.create!(
  :identifier => 99326,
  :option => o5
)

o6 = Option.create!(
  :name => 'EMS District 1 City of Asotin',
  :short_name => 'EMS Levy',
  :description => 'SHALL A SPECIAL LEVY BE COLLECTED IN 2012 OF THIRTY THOUSAND THREE HUNDRED SIXTY-NINE DOLLARS ($30,369.00) REQUIRING APPROXIMATELY FORTY CENTS  ($0.40) PER THOUSAND OF ASSESSED VALUATION FOR THE CITY OF ASOTIN TO PAY FOR EMERGENCY MEDICAL SERVICES. SPECIAL LEVY, YES_______  NO_______ ',
  :domain => 'City of Asotin',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z1 = DomainMap.create!(
  :identifier => 99402,
  :option => o6
)

o7 = Option.create!(
  :name => 'EMS District 2 City of Clarkston',
  :short_name => 'EMS Levy',
  :description => 'CITY OF CLARKSTON, WASHINGTON EMERGENCY MEDICAL SERVICES EXCESS  TAX LEVY  The City Council of the City of Clarkston, Washington, adopted Resolution No. 2011-08 concerning a proposition to finance emergency medical services. This proposition, if approved, would permit maintenance and operation of Rescue One Emergency Medical Services through the levy of a special excess tax for collection in 2012 of $486,834 requiring approximately $1.27 per thousand dollars of assessed value (based on 100% of true and fair value).  Should this proposition be approved?',
  :domain => 'City of Clarkston',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z2 = DomainMap.create!(
  :identifier => 99403,
  :option => o7
)

o8 = Option.create!(
  :name => 'Asotin County Fire Protection District No. 1 Emergency Medical Services Property Tax Levy',
  :short_name => 'EMS Levy',
  :description => 'PROPOSITION  Asotin County Fire Protection District No. 1 - Board of Commissioners Proposition Authorizing Emergency Medical Services Property Tax Levy.  Shall Asotin County Fire Protection District No. 1 be authorized to impose regular emergency medical services property tax levies of fifty cents or less per thousand dollars of assessed valuation for each of six consecutive years beginning in 2011 for collection in 2012 for the purpose of providing, maintaining and upgrading emergency medical services in the District. YES  _____  NO _____ ',
  :domain => 'Asotin County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z3 = DomainMap.create!(
  :identifier => 99401,
  :option => o8
)

z4 = DomainMap.create!(
  :identifier => 99402,
  :option => o8
)

z5 = DomainMap.create!(
  :identifier => 99403,
  :option => o8
)

o9 = Option.create!(
  :name => 'City of Palouse',
  :short_name => 'Street Levy',
  :description => 'For the purpose of funding street improvements and street oiling, the City Council of the City of Palouse proposes, pursuant to RCW 84.52.052, to impose an excess property tax levy upon all taxable property within the City in the amount of $40,000.00, an estimated $0.83 per $1,000.00, of assessed value in the year 2011 for collection in 2012, as provided in Resolution 2011-06.  Should this proposition be approved? ',
  :domain => 'City of Palouse',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z6 = DomainMap.create!(
  :identifier => 99161,
  :option => o9
)

o10 = Option.create!(
  :name => 'City of Palouse',
  :short_name => 'Swimming Pool Levy',
  :description => 'For the purpose of funding the operation and maintenance of the swimming pool, the City Council of the City of Palouse proposes, pursuant to RCW 84.52.052, to impose an excess property tax levy upon all taxable property within the City in the amount of $28,000.00 an estimated $0.58 per $1,000.00, of assessed value in the year 2011 for collection in 2012, as provided by Resolution 2011-07.  Should this proposition be approved? ',
  :domain => 'City of Palouse',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '2'
)

z7 = DomainMap.create!(
  :identifier => 99161,
  :option => o10
)

o11 = Option.create!(
  :name => 'City of Palouse',
  :short_name => 'EMS Levy',
  :description => 'Shall the City of Palouse be authorized to impose an additional property tax levy in the amount of fifty cents (.50) per thousand dollars of assessed valuation for each of six (6) consecutive years for provision of emergency medical services?',
  :domain => 'City of Palouse',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '3'
)

z8 = DomainMap.create!(
  :identifier => 99161,
  :option => o11
)

o12 = Option.create!(
  :name => 'CITY OF NEWPORT PROPERTY TAX LEVY LID LIFT DEDICATED TO STREET PRESERVATION AND REPAIR',
  :short_name => 'Street Levy',
  :description => 'PROPOSITION NO. 1  CITY OF NEWPORT PROPERTY TAX LEVY LID LIFT DEDICATED TO STREET PRESERVATION AND REPAIR  The Newport City Council adopted Resolution No. 80111 concerning a proposition to increase its regular property tax levy. If approved, this proposition would authorize the City to increase its regular property levy rate from its current level of $1.96 cents to a rate of $2.50 cents per $1,000 of assessed value for collection in 2012 and thereafter, which amount will be used for computing legal limits on levies in subsequent years pursuant to RCW Chapter 84.55, and the additional funds can only be used for street preservation and repair.  Should this proposition be:  ',
  :domain => 'City of Newport',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z9 = DomainMap.create!(
  :identifier => 99156,
  :option => o12
)

o13 = Option.create!(
  :name => 'SACHEEN LAKE SEWER AND WATER DISTRICT ONE YEAR EXCESS LEVY FOR MAINTENANCE AND OPERATION',
  :short_name => 'Water/Sewer Levy',
  :description => 'Shall the following taxes, in excess of regular, non voted property tax levies, for operation and maintenance purposes be levied for Sacheen Lake Water and Sewer Districts General Fund upon all taxable property within the District;  A tax of approximately $ 0.85 per thousand dollars of assessed valuation (based on true and fair value) to provide $60,545.00, said levy to be made in 2011 for collection in 2012. s General Fund upon all taxable property within the District;  A tax of approximately $ 0.85 per thousand dollars of assessed valuation (based on true and fair value) to provide $60,545.00, said levy to be made in 2011 for collection in 2012. ',
  :domain => 'Pend Oreille County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z10 = DomainMap.create!(
  :identifier => 99119,
  :option => o13
)

z11 = DomainMap.create!(
  :identifier => 99139,
  :option => o13
)

z12 = DomainMap.create!(
  :identifier => 99152,
  :option => o13
)

z13 = DomainMap.create!(
  :identifier => 99153,
  :option => o13
)

z14 = DomainMap.create!(
  :identifier => 99153,
  :option => o13
)

z15 = DomainMap.create!(
  :identifier => 99156,
  :option => o13
)

z16 = DomainMap.create!(
  :identifier => 99180,
  :option => o13
)

o14 = Option.create!(
  :name => 'SELKIRK SCHOOL DISTRICT NO. 70 CAPITAL LEVY FOR SCHOOL EXPANSION AND CONSOLIDATION',
  :short_name => 'School Levy',
  :description => 'The Board of Directors of Selkirk School District No. 70 adopted Resolution No. 10-11/09, concerning a proposition to finance school expansion and consolidation.  This proposition would authorize the District, as Phase I of a two phase project, to expand Selkirk Junior-Senior High School to consolidate Grades K-12 including constructing additional classrooms and new roof from the cafeteria to the south classrooms and levy the following excess taxes, on all taxable property within the District:  Approximate Levy Rate/$1,000 Collection Year  Assessed Value  Levy Amount 2012   $2.88               $750,000 2013   $2.88               $750,000  all as provided in Resolution No. 10-11/09.  Should this Phase I proposition be approved?',
  :domain => 'Pend Oreille County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z17 = DomainMap.create!(
  :identifier => 99119,
  :option => o14
)

z18 = DomainMap.create!(
  :identifier => 99139,
  :option => o14
)

z19 = DomainMap.create!(
  :identifier => 99152,
  :option => o14
)

z20 = DomainMap.create!(
  :identifier => 99153,
  :option => o14
)

z21 = DomainMap.create!(
  :identifier => 99153,
  :option => o14
)

z22 = DomainMap.create!(
  :identifier => 99156,
  :option => o14
)

z23 = DomainMap.create!(
  :identifier => 99180,
  :option => o14
)

o15 = Option.create!(
  :name => 'PROPOSITION WHETHER OR NOT THE DISTRICT SHOULD BE DISINCORPORATED',
  :short_name => 'Dissolve Water Dist.',
  :description => 'Resolution No. 11-04  PROPOSITION NO. 2  For Dissolution of Sacheen Lake Water and Sewer District ______  Against Dissolution of Sacheen Lake Water and Sewer District______ ',
  :domain => 'Pend Oreille County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '2'
)

z24 = DomainMap.create!(
  :identifier => 99119,
  :option => o15
)

z25 = DomainMap.create!(
  :identifier => 99139,
  :option => o15
)

z26 = DomainMap.create!(
  :identifier => 99152,
  :option => o15
)

z27 = DomainMap.create!(
  :identifier => 99153,
  :option => o15
)

z28 = DomainMap.create!(
  :identifier => 99153,
  :option => o15
)

z29 = DomainMap.create!(
  :identifier => 99156,
  :option => o15
)

z30 = DomainMap.create!(
  :identifier => 99180,
  :option => o15
)

o16 = Option.create!(
  :name => 'HOSPITAL DISTRICT ONE YEAR EXCESS LEVY',
  :short_name => 'Hospital Levy',
  :description => 'The Douglas County Hospital District No.2 (Waterville Clinic and Ambulance) Board of Commissioners adopted Resolution #60 on July 20, 2011, containing a proposition to finance maintenance and operation. This proposition would authorize the district to levy excess taxes upon all taxable property within the district in the sum of $65,000, requiring collection of approximately $0.40 per $1,000 of assessed valuation in 2012. Should this proposition be approved?',
  :domain => 'Douglas County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z31 = DomainMap.create!(
  :identifier => 98813,
  :option => o16
)

z32 = DomainMap.create!(
  :identifier => 98858,
  :option => o16
)

z33 = DomainMap.create!(
  :identifier => 98802,
  :option => o16
)

z34 = DomainMap.create!(
  :identifier => 98802,
  :option => o16
)

z35 = DomainMap.create!(
  :identifier => 98858,
  :option => o16
)

z36 = DomainMap.create!(
  :identifier => 98830,
  :option => o16
)

z37 = DomainMap.create!(
  :identifier => 98843,
  :option => o16
)

z38 = DomainMap.create!(
  :identifier => 98845,
  :option => o16
)

z39 = DomainMap.create!(
  :identifier => 98850,
  :option => o16
)

z40 = DomainMap.create!(
  :identifier => 98858,
  :option => o16
)

z41 = DomainMap.create!(
  :identifier => 98802,
  :option => o16
)

z42 = DomainMap.create!(
  :identifier => 98858,
  :option => o16
)

o17 = Option.create!(
  :name => 'ONE YEAR MAINTENANCE AND OPERATIONS EXCESS TAX LEVY',
  :short_name => 'Cemetary Dist.',
  :description => 'ONE YEAR MAINTENANCE AND OPERATIONS EXCESS TAX LEVY  The Douglas County Cemetery District No. 2 Board of Commissioners adopted Resolution #2011/002 on August 8, 2011, containing a proposition to finance maintenance and operations.  This proposition would authorize the district to levy excess taxes upon all taxable property within the district in the sum of $70,000, requiring collection of approximately $0.53 per $1,000 of assessed valuation in 2012.  Should this proposition be approved?    YES . . . .  _____    NO   . . . .  _____  ',
  :domain => 'Douglas County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '4'
)

z43 = DomainMap.create!(
  :identifier => 98813,
  :option => o17
)

z44 = DomainMap.create!(
  :identifier => 98858,
  :option => o17
)

z45 = DomainMap.create!(
  :identifier => 98802,
  :option => o17
)

z46 = DomainMap.create!(
  :identifier => 98802,
  :option => o17
)

z47 = DomainMap.create!(
  :identifier => 98858,
  :option => o17
)

z48 = DomainMap.create!(
  :identifier => 98830,
  :option => o17
)

z49 = DomainMap.create!(
  :identifier => 98843,
  :option => o17
)

z50 = DomainMap.create!(
  :identifier => 98845,
  :option => o17
)

z51 = DomainMap.create!(
  :identifier => 98850,
  :option => o17
)

z52 = DomainMap.create!(
  :identifier => 98858,
  :option => o17
)

z53 = DomainMap.create!(
  :identifier => 98802,
  :option => o17
)

z54 = DomainMap.create!(
  :identifier => 98858,
  :option => o17
)

o18 = Option.create!(
  :name => 'Town of Farmington',
  :short_name => 'Current Expense Levy',
  :description => 'Shall the Town of Farmington levy a special tax of $15,000, an estimated $2.40, per $1,000  of the 2011 assessed valuation, for Current Expense Fund, for collection in 2012 be approved?',
  :domain => 'Town of Farmington',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '10'
)

z55 = DomainMap.create!(
  :identifier => 99104,
  :option => o18
)

z56 = DomainMap.create!(
  :identifier => 99128,
  :option => o18
)

o19 = Option.create!(
  :name => 'Town of Farmington',
  :short_name => 'Special Eqpt Levy',
  :description => 'Shall the Town of Farmington levy a special tax of $5,000, an estimated $0.93, per one thousand dollars of the 2011 assessed valuation, for Special Equipment Fund, for collection in 2012, be approved?',
  :domain => 'Town of Farmington',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '11'
)

z57 = DomainMap.create!(
  :identifier => 99104,
  :option => o19
)

z58 = DomainMap.create!(
  :identifier => 99128,
  :option => o19
)

o20 = Option.create!(
  :name => 'Town of Farmington',
  :short_name => 'Street Levy',
  :description => 'Shall the Town of Farmington levy a special tax of $12,000, an estimated $2.24, per $1,000.00 dollars of the 2011 assessed valuation, for City Street Maintenance Fund, for collection in 2012, be approved?',
  :domain => 'Town of Farmington',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '9'
)

z59 = DomainMap.create!(
  :identifier => 99104,
  :option => o20
)

z60 = DomainMap.create!(
  :identifier => 99128,
  :option => o20
)

o21 = Option.create!(
  :name => 'Proposition No. 1',
  :short_name => 'Criminal Justice Levy',
  :description => ' The Board of Franklin County Commissioners adopted Resolution No. 2011, concerning a proposition for a county and cities criminal justice and public purposes sales and use tax. This proposition would authorize the sales and use tax in Franklin County and Cities therein be increased three-tenths of one percent (0.3%) for thirty years to improve, expand, operate, and maintain the County jail, and support criminal justice or public purposes as permitted bv law. Should this proposition be approved?',
  :domain => 'Franklin County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '2'
)

z61 = DomainMap.create!(
  :identifier => 99343,
  :option => o21
)

z62 = DomainMap.create!(
  :identifier => 99326,
  :option => o21
)

z63 = DomainMap.create!(
  :identifier => 99330,
  :option => o21
)

z64 = DomainMap.create!(
  :identifier => 99335,
  :option => o21
)

z65 = DomainMap.create!(
  :identifier => 99343,
  :option => o21
)

z66 = DomainMap.create!(
  :identifier => 99301,
  :option => o21
)

z67 = DomainMap.create!(
  :identifier => 99302,
  :option => o21
)

z68 = DomainMap.create!(
  :identifier => 99302,
  :option => o21
)

o22 = Option.create!(
  :name => 'Resolution No. CE 11-38B ',
  :short_name => 'Mosquito District',
  :description => 'MOSQUITO CONTROL DISTRICT FORMATION  Shall a mosquito control district be established for the area described in Resolution No. CE 11-38B adopted on August 8, 2011, by the Board of County Commissioners?     YES  _____   NO  _____   ',
  :domain => 'Town of Waterville',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '2'
)

z69 = DomainMap.create!(
  :identifier => 98858,
  :option => o22
)

o23 = Option.create!(
  :name => 'MOSQUITO CONTROL DISTRICT ONE YEAR LEVY',
  :short_name => 'Mosquito Levy',
  :description => 'MOSQUITO CONTROL DISTRICT ONE YEAR LEVY  Shall the mosquito control district, if formed, levy a general tax of twenty-five cents ($0.25) per thousand dollars of assessed value for one year upon all taxable property within the district in excess of constitutional and/or statutory tax limits for authorized purposes of the district?    LEVY YES ______  LEVY NO _______  ',
  :domain => 'Town of Waterville',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '3'
)

z70 = DomainMap.create!(
  :identifier => 98858,
  :option => o23
)

o24 = Option.create!(
  :name => 'Permanent Regular Levy Lid Lift',
  :short_name => 'Levy Lid Lift',
  :description => 'Permanent Regular Levy Lid Lift  The Waterville Town Council adopted Resolution No. 2011-05 containing a  Proposition that would authorize regular property taxes at the maximum rate of $2.80 per $1,000 of assessed valuation for the year 2012. This is a  permanent levy lid lift. For a minimum period of six (6) years, $.50 per  $1,000 of the levy increase shall be dedicated to continuing maintenance and  operation of the Towns swimming pool. Should this proposition be  approved?s swimming pool. Should this proposition be  approved?',
  :domain => 'Town of Waterville',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '5'
)

z71 = DomainMap.create!(
  :identifier => 98858,
  :option => o24
)

o25 = Option.create!(
  :name => 'City of Tekoa',
  :short_name => 'Street Levy',
  :description => 'Shall the City of Tekoa levy a special tax in the amount of $50,000.00, an estimated $2.19 per one thousand dollars of assessed valuation, for collection in 2012, for operation and maintenance in the Street Department?',
  :domain => 'City of Tekoa',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '4'
)

z72 = DomainMap.create!(
  :identifier => 99033,
  :option => o25
)

o26 = Option.create!(
  :name => 'Town of Albion',
  :short_name => 'EMS Levy',
  :description => 'Shall the Town of Albion levy a special tax levy of $1,000, an estimated $0.50 per one thousand dollars of assessed valuation for six consecutive years beginning in 2012 for Emergency Medical Services?',
  :domain => 'Town of Albion',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '5'
)

z73 = DomainMap.create!(
  :identifier => 99102,
  :option => o26
)

o27 = Option.create!(
  :name => 'Town of Colton',
  :short_name => 'Street/Water Levy',
  :description => 'Shall the Town of Colton be authorized to levy additional taxes by an excess levy for collection in 2012 of approximately $1.20 per $1,000.00 of assessed value, to raise the $30,000.00 for General Operations, Improvements of the Town Streets and Water System?',
  :domain => 'Town of Colton',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '6'
)

z74 = DomainMap.create!(
  :identifier => 99113,
  :option => o27
)

o28 = Option.create!(
  :name => 'Town of Endicott',
  :short_name => 'Street Levy',
  :description => 'Shall the Town of Endicott be authorized to impose a special tax levy in 2011for collection in 2012 of $20,000 for Street Work and Maintenance?',
  :domain => 'Town of Endicott',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '7'
)

z75 = DomainMap.create!(
  :identifier => 99125,
  :option => o28
)

o29 = Option.create!(
  :name => 'Town of Endicott',
  :short_name => 'City Park Levy',
  :description => 'Shall the Town of Endicott be authorized to impose a special tax levy in 2011 for collection in 2012 of $7,000.00 for City Park Maintenance?',
  :domain => 'Town of Endicott',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '8'
)

z76 = DomainMap.create!(
  :identifier => 99125,
  :option => o29
)

o30 = Option.create!(
  :name => 'Veterans and Human Services Levy',
  :short_name => 'Veterans Svcs.',
  :description => 'The Kitsap County Board of Commissioners approved Resolution Nos. 123-2011 and 124-2011 concerning funding for veterans, health and human services.  This proposition would fund capital facilities and services that reduce medical costs, homelessness and criminal justice system involvement, with half of the proceeds supporting veterans, military personnel and their families, and the other half supporting other families in need.  It would authorize Kitsap County to increase its projected regular property tax levy rate of $1.10 by up to 5 cents per $1,000 of assessed valuation, to $1.15, for collection in 2012, with levy increases in each of the following five years limited as provided by chapter 84.55 RCW. ',
  :domain => 'Kitsap County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z77 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z78 = DomainMap.create!(
  :identifier => 98110,
  :option => o30
)

z79 = DomainMap.create!(
  :identifier => 98110,
  :option => o30
)

z80 = DomainMap.create!(
  :identifier => 98315,
  :option => o30
)

z81 = DomainMap.create!(
  :identifier => 98315,
  :option => o30
)

z82 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z83 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z84 = DomainMap.create!(
  :identifier => 98310,
  :option => o30
)

z85 = DomainMap.create!(
  :identifier => 98311,
  :option => o30
)

z86 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z87 = DomainMap.create!(
  :identifier => 98314,
  :option => o30
)

z88 = DomainMap.create!(
  :identifier => 98337,
  :option => o30
)

z89 = DomainMap.create!(
  :identifier => 98310,
  :option => o30
)

z90 = DomainMap.create!(
  :identifier => 98322,
  :option => o30
)

z91 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z92 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z93 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z94 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z95 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z96 = DomainMap.create!(
  :identifier => 98310,
  :option => o30
)

z97 = DomainMap.create!(
  :identifier => 98310,
  :option => o30
)

z98 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z99 = DomainMap.create!(
  :identifier => 98346,
  :option => o30
)

z100 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z101 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z102 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z103 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z104 = DomainMap.create!(
  :identifier => 98359,
  :option => o30
)

z105 = DomainMap.create!(
  :identifier => 98310,
  :option => o30
)

z106 = DomainMap.create!(
  :identifier => 98337,
  :option => o30
)

z107 = DomainMap.create!(
  :identifier => 98340,
  :option => o30
)

z108 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z109 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z110 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z111 = DomainMap.create!(
  :identifier => 98342,
  :option => o30
)

z112 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z113 = DomainMap.create!(
  :identifier => 98345,
  :option => o30
)

z114 = DomainMap.create!(
  :identifier => 98346,
  :option => o30
)

z115 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z116 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z117 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z118 = DomainMap.create!(
  :identifier => 98364,
  :option => o30
)

z119 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z120 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z121 = DomainMap.create!(
  :identifier => 98353,
  :option => o30
)

z122 = DomainMap.create!(
  :identifier => 98061,
  :option => o30
)

z123 = DomainMap.create!(
  :identifier => 98380,
  :option => o30
)

z124 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z125 = DomainMap.create!(
  :identifier => 98310,
  :option => o30
)

z126 = DomainMap.create!(
  :identifier => 98380,
  :option => o30
)

z127 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z128 = DomainMap.create!(
  :identifier => 98359,
  :option => o30
)

z129 = DomainMap.create!(
  :identifier => 98359,
  :option => o30
)

z130 = DomainMap.create!(
  :identifier => 98383,
  :option => o30
)

z131 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z132 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z133 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z134 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z135 = DomainMap.create!(
  :identifier => 98364,
  :option => o30
)

z136 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z137 = DomainMap.create!(
  :identifier => 98367,
  :option => o30
)

z138 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z139 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z140 = DomainMap.create!(
  :identifier => 98314,
  :option => o30
)

z141 = DomainMap.create!(
  :identifier => 98378,
  :option => o30
)

z142 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z143 = DomainMap.create!(
  :identifier => 98061,
  :option => o30
)

z144 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z145 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z146 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z147 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z148 = DomainMap.create!(
  :identifier => 98380,
  :option => o30
)

z149 = DomainMap.create!(
  :identifier => 98110,
  :option => o30
)

z150 = DomainMap.create!(
  :identifier => 98310,
  :option => o30
)

z151 = DomainMap.create!(
  :identifier => 98311,
  :option => o30
)

z152 = DomainMap.create!(
  :identifier => 98315,
  :option => o30
)

z153 = DomainMap.create!(
  :identifier => 98383,
  :option => o30
)

z154 = DomainMap.create!(
  :identifier => 98384,
  :option => o30
)

z155 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z156 = DomainMap.create!(
  :identifier => 98386,
  :option => o30
)

z157 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z158 = DomainMap.create!(
  :identifier => 98392,
  :option => o30
)

z159 = DomainMap.create!(
  :identifier => 98393,
  :option => o30
)

z160 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z161 = DomainMap.create!(
  :identifier => 98370,
  :option => o30
)

z162 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z163 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

z164 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z165 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z166 = DomainMap.create!(
  :identifier => 98312,
  :option => o30
)

z167 = DomainMap.create!(
  :identifier => 98366,
  :option => o30
)

o31 = Option.create!(
  :name => 'Formation of Port of Bainbridge Island',
  :short_name => 'Port Formation',
  :description => 'The Kitsap County Board of Commissioners adopted Resolution No. 110-2011 concerning formation of the Port of Bainbridge Island.  If approved, this proposition would form the Port of Bainbridge Island, with boundaries coextensive with those of the City of Bainbridge Island and governed by a five-member Port Commission with members elected at large.  Should the Port of Bainbridge Island be formed? (Pursuant to RCW 53.04.023 & BOCC Res. No. 110-2011)',
  :domain => 'Kitsap County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z168 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z169 = DomainMap.create!(
  :identifier => 98110,
  :option => o31
)

z170 = DomainMap.create!(
  :identifier => 98110,
  :option => o31
)

z171 = DomainMap.create!(
  :identifier => 98315,
  :option => o31
)

z172 = DomainMap.create!(
  :identifier => 98315,
  :option => o31
)

z173 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z174 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z175 = DomainMap.create!(
  :identifier => 98310,
  :option => o31
)

z176 = DomainMap.create!(
  :identifier => 98311,
  :option => o31
)

z177 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z178 = DomainMap.create!(
  :identifier => 98314,
  :option => o31
)

z179 = DomainMap.create!(
  :identifier => 98337,
  :option => o31
)

z180 = DomainMap.create!(
  :identifier => 98310,
  :option => o31
)

z181 = DomainMap.create!(
  :identifier => 98322,
  :option => o31
)

z182 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z183 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z184 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z185 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z186 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z187 = DomainMap.create!(
  :identifier => 98310,
  :option => o31
)

z188 = DomainMap.create!(
  :identifier => 98310,
  :option => o31
)

z189 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z190 = DomainMap.create!(
  :identifier => 98346,
  :option => o31
)

z191 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z192 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z193 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z194 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z195 = DomainMap.create!(
  :identifier => 98359,
  :option => o31
)

z196 = DomainMap.create!(
  :identifier => 98310,
  :option => o31
)

z197 = DomainMap.create!(
  :identifier => 98337,
  :option => o31
)

z198 = DomainMap.create!(
  :identifier => 98340,
  :option => o31
)

z199 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z200 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z201 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z202 = DomainMap.create!(
  :identifier => 98342,
  :option => o31
)

z203 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z204 = DomainMap.create!(
  :identifier => 98345,
  :option => o31
)

z205 = DomainMap.create!(
  :identifier => 98346,
  :option => o31
)

z206 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z207 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z208 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z209 = DomainMap.create!(
  :identifier => 98364,
  :option => o31
)

z210 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z211 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z212 = DomainMap.create!(
  :identifier => 98353,
  :option => o31
)

z213 = DomainMap.create!(
  :identifier => 98061,
  :option => o31
)

z214 = DomainMap.create!(
  :identifier => 98380,
  :option => o31
)

z215 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z216 = DomainMap.create!(
  :identifier => 98310,
  :option => o31
)

z217 = DomainMap.create!(
  :identifier => 98380,
  :option => o31
)

z218 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z219 = DomainMap.create!(
  :identifier => 98359,
  :option => o31
)

z220 = DomainMap.create!(
  :identifier => 98359,
  :option => o31
)

z221 = DomainMap.create!(
  :identifier => 98383,
  :option => o31
)

z222 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z223 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z224 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z225 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z226 = DomainMap.create!(
  :identifier => 98364,
  :option => o31
)

z227 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z228 = DomainMap.create!(
  :identifier => 98367,
  :option => o31
)

z229 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z230 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z231 = DomainMap.create!(
  :identifier => 98314,
  :option => o31
)

z232 = DomainMap.create!(
  :identifier => 98378,
  :option => o31
)

z233 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z234 = DomainMap.create!(
  :identifier => 98061,
  :option => o31
)

z235 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z236 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z237 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z238 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z239 = DomainMap.create!(
  :identifier => 98380,
  :option => o31
)

z240 = DomainMap.create!(
  :identifier => 98110,
  :option => o31
)

z241 = DomainMap.create!(
  :identifier => 98310,
  :option => o31
)

z242 = DomainMap.create!(
  :identifier => 98311,
  :option => o31
)

z243 = DomainMap.create!(
  :identifier => 98315,
  :option => o31
)

z244 = DomainMap.create!(
  :identifier => 98383,
  :option => o31
)

z245 = DomainMap.create!(
  :identifier => 98384,
  :option => o31
)

z246 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z247 = DomainMap.create!(
  :identifier => 98386,
  :option => o31
)

z248 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z249 = DomainMap.create!(
  :identifier => 98392,
  :option => o31
)

z250 = DomainMap.create!(
  :identifier => 98393,
  :option => o31
)

z251 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z252 = DomainMap.create!(
  :identifier => 98370,
  :option => o31
)

z253 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z254 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

z255 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z256 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z257 = DomainMap.create!(
  :identifier => 98312,
  :option => o31
)

z258 = DomainMap.create!(
  :identifier => 98366,
  :option => o31
)

o32 = Option.create!(
  :name => 'Proposed Charter Amendment to Reduce the Size of City Council',
  :short_name => 'Council Size Red.',
  :description => 'The Bremerton City Council adopted Resolution No. 3139, approving a proposition to be sent to the voters to amend the Bremerton City Charter reducing the size of the City Council.\n\nIf approved, this proposition amends the City Charter reducing the number of Council members and Council districts from nine to seven, and makes other related changes.  Council members elected in 2011 to represent current Council districts will serve two year terms.  In 2013, the seven new Council districts, as redistricted, will elect new Council members.  These Council members will initially serve staggered terms beginning in 2014.  Thereafter, all Council members shall serve four year terms.',
  :domain => 'City of Bremerton',
  :domain_short => 'city',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z259 = DomainMap.create!(
  :identifier => 98310,
  :option => o32
)

z260 = DomainMap.create!(
  :identifier => 98311,
  :option => o32
)

z261 = DomainMap.create!(
  :identifier => 98312,
  :option => o32
)

z262 = DomainMap.create!(
  :identifier => 98314,
  :option => o32
)

z263 = DomainMap.create!(
  :identifier => 98337,
  :option => o32
)

z264 = DomainMap.create!(
  :identifier => 98310,
  :option => o32
)

o33 = Option.create!(
  :name => 'Enlargement of Port of Tracyton',
  :short_name => 'Port Enlargement',
  :description => 'This proposition concerns the enlargement of the Port of Tracyton.  The proposition would authorize the Port of Tracyton to enlarge its existing geographical boundaries by annexing to the Port the territory legally described in Port of Tracyton Resolution No. 2011-01. Should this proposition be enacted into law? (Pursuant to RCW 53.04.080 and Port District Resolution No. 2011-01)',
  :domain => 'Port of Tracyton',
  :domain_short => 'port',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z265 = DomainMap.create!(
  :identifier => 98393,
  :option => o33
)

o34 = Option.create!(
  :name => 'EMS Levy Authorization',
  :short_name => 'EMS Levy',
  :description => 'The Board of Yakima County Commissioners adopted Resolution No. 317-2011 concerning a proposition to finance emergency medical care and emergency medical services.  This proposition would authorize Yakima County to continue to impose regular property tax levies of twenty-five cents per thousand dollars of assessed valuation (.25/$1,000.00) or less, for the ten consecutive years beginning January 1, 2014, the proceeds to be used to provide emergency medical care or emergency medical services according to RCW 84.52.069.  Should this proposition be approved?',
  :domain => 'Yakima County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '2'
)

z266 = DomainMap.create!(
  :identifier => 98902,
  :option => o34
)

z267 = DomainMap.create!(
  :identifier => 98920,
  :option => o34
)

z268 = DomainMap.create!(
  :identifier => 98921,
  :option => o34
)

z269 = DomainMap.create!(
  :identifier => 98937,
  :option => o34
)

z270 = DomainMap.create!(
  :identifier => 98923,
  :option => o34
)

z271 = DomainMap.create!(
  :identifier => 98951,
  :option => o34
)

z272 = DomainMap.create!(
  :identifier => 98901,
  :option => o34
)

z273 = DomainMap.create!(
  :identifier => 98903,
  :option => o34
)

z274 = DomainMap.create!(
  :identifier => 98902,
  :option => o34
)

z275 = DomainMap.create!(
  :identifier => 98904,
  :option => o34
)

z276 = DomainMap.create!(
  :identifier => 98937,
  :option => o34
)

z277 = DomainMap.create!(
  :identifier => 98930,
  :option => o34
)

z278 = DomainMap.create!(
  :identifier => 98932,
  :option => o34
)

z279 = DomainMap.create!(
  :identifier => 98933,
  :option => o34
)

z280 = DomainMap.create!(
  :identifier => 98902,
  :option => o34
)

z281 = DomainMap.create!(
  :identifier => 98935,
  :option => o34
)

z282 = DomainMap.create!(
  :identifier => 98936,
  :option => o34
)

z283 = DomainMap.create!(
  :identifier => 98936,
  :option => o34
)

z284 = DomainMap.create!(
  :identifier => 98937,
  :option => o34
)

z285 = DomainMap.create!(
  :identifier => 98937,
  :option => o34
)

z286 = DomainMap.create!(
  :identifier => 98938,
  :option => o34
)

z287 = DomainMap.create!(
  :identifier => 98939,
  :option => o34
)

z288 = DomainMap.create!(
  :identifier => 98902,
  :option => o34
)

z289 = DomainMap.create!(
  :identifier => 98937,
  :option => o34
)

z290 = DomainMap.create!(
  :identifier => 98951,
  :option => o34
)

z291 = DomainMap.create!(
  :identifier => 98942,
  :option => o34
)

z292 = DomainMap.create!(
  :identifier => 98903,
  :option => o34
)

z293 = DomainMap.create!(
  :identifier => 98901,
  :option => o34
)

z294 = DomainMap.create!(
  :identifier => 98903,
  :option => o34
)

z295 = DomainMap.create!(
  :identifier => 98944,
  :option => o34
)

z296 = DomainMap.create!(
  :identifier => 98902,
  :option => o34
)

z297 = DomainMap.create!(
  :identifier => 98947,
  :option => o34
)

z298 = DomainMap.create!(
  :identifier => 98948,
  :option => o34
)

z299 = DomainMap.create!(
  :identifier => 98901,
  :option => o34
)

z300 = DomainMap.create!(
  :identifier => 98903,
  :option => o34
)

z301 = DomainMap.create!(
  :identifier => 98951,
  :option => o34
)

z302 = DomainMap.create!(
  :identifier => 98902,
  :option => o34
)

z303 = DomainMap.create!(
  :identifier => 98902,
  :option => o34
)

z304 = DomainMap.create!(
  :identifier => 98937,
  :option => o34
)

z305 = DomainMap.create!(
  :identifier => 98952,
  :option => o34
)

z306 = DomainMap.create!(
  :identifier => 98901,
  :option => o34
)

z307 = DomainMap.create!(
  :identifier => 98902,
  :option => o34
)

z308 = DomainMap.create!(
  :identifier => 98903,
  :option => o34
)

z309 = DomainMap.create!(
  :identifier => 98904,
  :option => o34
)

z310 = DomainMap.create!(
  :identifier => 98907,
  :option => o34
)

z311 = DomainMap.create!(
  :identifier => 98908,
  :option => o34
)

z312 = DomainMap.create!(
  :identifier => 98909,
  :option => o34
)

z313 = DomainMap.create!(
  :identifier => 98901,
  :option => o34
)

z314 = DomainMap.create!(
  :identifier => 98953,
  :option => o34
)

o35 = Option.create!(
  :name => 'Yakima County Home Rule',
  :short_name => 'Home Rule Charter',
  :description => 'Proposition No. 1 concerns a proposal to frame a home rule charter for Yakima County. If approved, a board of fifteen (15) freeholders would be elected for the purpose of drafting a home rule charter for submission to the voters of Yakima County to adopt or reject pursuant to Article XI, Section 4, of the Washington State Constitution. Should this proposition be approved?',
  :domain => 'Yakima County',
  :domain_short => 'county',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z315 = DomainMap.create!(
  :identifier => 98902,
  :option => o35
)

z316 = DomainMap.create!(
  :identifier => 98920,
  :option => o35
)

z317 = DomainMap.create!(
  :identifier => 98921,
  :option => o35
)

z318 = DomainMap.create!(
  :identifier => 98937,
  :option => o35
)

z319 = DomainMap.create!(
  :identifier => 98923,
  :option => o35
)

z320 = DomainMap.create!(
  :identifier => 98951,
  :option => o35
)

z321 = DomainMap.create!(
  :identifier => 98901,
  :option => o35
)

z322 = DomainMap.create!(
  :identifier => 98903,
  :option => o35
)

z323 = DomainMap.create!(
  :identifier => 98902,
  :option => o35
)

z324 = DomainMap.create!(
  :identifier => 98904,
  :option => o35
)

z325 = DomainMap.create!(
  :identifier => 98937,
  :option => o35
)

z326 = DomainMap.create!(
  :identifier => 98930,
  :option => o35
)

z327 = DomainMap.create!(
  :identifier => 98932,
  :option => o35
)

z328 = DomainMap.create!(
  :identifier => 98933,
  :option => o35
)

z329 = DomainMap.create!(
  :identifier => 98902,
  :option => o35
)

z330 = DomainMap.create!(
  :identifier => 98935,
  :option => o35
)

z331 = DomainMap.create!(
  :identifier => 98936,
  :option => o35
)

z332 = DomainMap.create!(
  :identifier => 98936,
  :option => o35
)

z333 = DomainMap.create!(
  :identifier => 98937,
  :option => o35
)

z334 = DomainMap.create!(
  :identifier => 98937,
  :option => o35
)

z335 = DomainMap.create!(
  :identifier => 98938,
  :option => o35
)

z336 = DomainMap.create!(
  :identifier => 98939,
  :option => o35
)

z337 = DomainMap.create!(
  :identifier => 98902,
  :option => o35
)

z338 = DomainMap.create!(
  :identifier => 98937,
  :option => o35
)

z339 = DomainMap.create!(
  :identifier => 98951,
  :option => o35
)

z340 = DomainMap.create!(
  :identifier => 98942,
  :option => o35
)

z341 = DomainMap.create!(
  :identifier => 98903,
  :option => o35
)

z342 = DomainMap.create!(
  :identifier => 98901,
  :option => o35
)

z343 = DomainMap.create!(
  :identifier => 98903,
  :option => o35
)

z344 = DomainMap.create!(
  :identifier => 98944,
  :option => o35
)

z345 = DomainMap.create!(
  :identifier => 98902,
  :option => o35
)

z346 = DomainMap.create!(
  :identifier => 98947,
  :option => o35
)

z347 = DomainMap.create!(
  :identifier => 98948,
  :option => o35
)

z348 = DomainMap.create!(
  :identifier => 98901,
  :option => o35
)

z349 = DomainMap.create!(
  :identifier => 98903,
  :option => o35
)

z350 = DomainMap.create!(
  :identifier => 98951,
  :option => o35
)

z351 = DomainMap.create!(
  :identifier => 98902,
  :option => o35
)

z352 = DomainMap.create!(
  :identifier => 98902,
  :option => o35
)

z353 = DomainMap.create!(
  :identifier => 98937,
  :option => o35
)

z354 = DomainMap.create!(
  :identifier => 98952,
  :option => o35
)

z355 = DomainMap.create!(
  :identifier => 98901,
  :option => o35
)

z356 = DomainMap.create!(
  :identifier => 98902,
  :option => o35
)

z357 = DomainMap.create!(
  :identifier => 98903,
  :option => o35
)

z358 = DomainMap.create!(
  :identifier => 98904,
  :option => o35
)

z359 = DomainMap.create!(
  :identifier => 98907,
  :option => o35
)

z360 = DomainMap.create!(
  :identifier => 98908,
  :option => o35
)

z361 = DomainMap.create!(
  :identifier => 98909,
  :option => o35
)

z362 = DomainMap.create!(
  :identifier => 98901,
  :option => o35
)

z363 = DomainMap.create!(
  :identifier => 98953,
  :option => o35
)

o36 = Option.create!(
  :name => 'Naches Park & Recreation District Special Levy',
  :short_name => 'Parks Levy',
  :description => 'The Commissioners of the Naches Park and Recreation District adopted Resolution 2011-09 concerning a proposition to finance the general operating and equipment expenses of the District.  This proposition would authorize the district to levy $95,000 in excess property taxes (approximately $.58 per $1,000 of assessed valuation) to be collected in 2012 and again in 2013 to meet general operating and equipment expenses.  Should this proposition be approved?',
  :domain => 'Town of Naches',
  :domain_short => 'town',
  :url => '',
  :category => 'Proposition',
  :designator => '1'
)

z364 = DomainMap.create!(
  :identifier => 98937,
  :option => o36
)

o37 = Option.create!(
  :name => 'Levy for Criminal Justice Services and Cash Reserve Stabilization',
  :short_name => 'Criminal Justice Levy',
  :description => 'The Carnation City Council has passed Resolution No. 366, placing funding for criminal justice services and stabilization of the City\'s monetary reserves before the voters.\n\nThis six-year proposition would increase the regular property tax rate for collection in 2012 by $0.61 to $1.90 per $1,000 of assessed valuation.  The 2012 levy amount would become the base upon which levy increases would be computed for each of the five succeeding years.  The revenue would be used to fund criminal justice services, including police, jail, prosecution, courts, public defender, and domestic violence advocacy, and to help stabilize the City\'s monetary reserves.',
  :domain => 'City of Carnation',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40321&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z365 = DomainMap.create!(
  :identifier => 98014,
  :option => o37
)

o38 = Option.create!(
  :name => 'Utility Occupation Tax for Des Moines Beach Park and Streets',
  :short_name => 'Historic Bldgs, Streets',
  :description => 'The Des Moines City Council adopted Resolution No. 1169 concerning a proposition to increase the City Utility Occupation Tax to restore Beach Park Historic District buildings and facilities;  fund maintenance and operations;  and for City street paving improvements.  This proposition would restore Des Moines Beach Park Historic Buildings and facilities; fund maintenance and operations; and improve City streets to prevent their further deterioration.  This proposition increases the current 6% utility occupation tax to 9% authorizing:  (1) 1% for Beach Park capital projects for 20 years or until capital bonds are repaid and thereafter that 1% tax ends; (2) 0.5% for Beach Park maintenance and operations; and (3) 1.5% for City street paving improvements.',
  :domain => 'City of Des Moines',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40322&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z366 = DomainMap.create!(
  :identifier => 98148,
  :option => o38
)

z367 = DomainMap.create!(
  :identifier => 98198,
  :option => o38
)

o39 = Option.create!(
  :name => 'Levy Lid Lift for Street Improvements',
  :short_name => 'Street Levy',
  :description => 'The City Council of the City of Pacific, adopted Resolution No. 1076 concerning a property tax levy increase for street improvements.  If approved, this proposition would (1) increase the regular property tax levy above the increase allowed under Ch. 84.55 RCW, to a total rate of $1.66396/$1,000 assessed value for collection in 2012;  (2) increase the 2013-2017 maximum permitted levy amounts by inflation (measured by CPI); and (3) dedicate the increase to purchasing street repair and improvement materials.  This measure expires after 2017. ',
  :domain => 'City of Pacific',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40323&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z368 = DomainMap.create!(
  :identifier => 98047,
  :option => o39
)

o40 = Option.create!(
  :name => 'hange in Plan of Governmen',
  :short_name => 'Mayor/Council?',
  :description => 'Shall the City of SeaTac abandon its present Council-Manager plan of government under which it currently operates under RCW 35A.13 and adopt in its place the Mayor-Council plan of government under the provisions of RCW 35A.12?',
  :domain => 'City of SeaTac',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40324&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z369 = DomainMap.create!(
  :identifier => 98148,
  :option => o40
)

z370 = DomainMap.create!(
  :identifier => 98158,
  :option => o40
)

z371 = DomainMap.create!(
  :identifier => 98168,
  :option => o40
)

z372 = DomainMap.create!(
  :identifier => 98188,
  :option => o40
)

z373 = DomainMap.create!(
  :identifier => 98198,
  :option => o40
)

z374 = DomainMap.create!(
  :identifier => 98158,
  :option => o40
)

o41 = Option.create!(
  :name => 'Regular Tax Levy Including Families and Education',
  :short_name => 'Families & Educ.',
  :description => 'The City of Seattle\'s Proposition concerns renewing and enhancing Education-Support Services to improve academic achievement.\n\nThis proposition would fund City services, including school readiness, academic achievement in elementary, middle and high school, college/career preparation, and student health and community partnerships as provided in Ordinance 123567. It authorizes regular property taxes above RCW 84.55 limits, allowing additional 2012 collection of up to $32,101,000 (approximately $0.27/$1000 assessed value) and up to $231,562,000 over seven years. In 2012, total City taxes collected would not exceed $3.60 per $1,000 of assessed value.',
  :domain => 'City of Seattle',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40325&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z375 = DomainMap.create!(
  :identifier => 98101,
  :option => o41
)

z376 = DomainMap.create!(
  :identifier => 98102,
  :option => o41
)

z377 = DomainMap.create!(
  :identifier => 98103,
  :option => o41
)

z378 = DomainMap.create!(
  :identifier => 98104,
  :option => o41
)

z379 = DomainMap.create!(
  :identifier => 98105,
  :option => o41
)

z380 = DomainMap.create!(
  :identifier => 98106,
  :option => o41
)

z381 = DomainMap.create!(
  :identifier => 98107,
  :option => o41
)

z382 = DomainMap.create!(
  :identifier => 98108,
  :option => o41
)

z383 = DomainMap.create!(
  :identifier => 98109,
  :option => o41
)

z384 = DomainMap.create!(
  :identifier => 98111,
  :option => o41
)

z385 = DomainMap.create!(
  :identifier => 98112,
  :option => o41
)

z386 = DomainMap.create!(
  :identifier => 98113,
  :option => o41
)

z387 = DomainMap.create!(
  :identifier => 98114,
  :option => o41
)

z388 = DomainMap.create!(
  :identifier => 98115,
  :option => o41
)

z389 = DomainMap.create!(
  :identifier => 98116,
  :option => o41
)

z390 = DomainMap.create!(
  :identifier => 98117,
  :option => o41
)

z391 = DomainMap.create!(
  :identifier => 98118,
  :option => o41
)

z392 = DomainMap.create!(
  :identifier => 98119,
  :option => o41
)

z393 = DomainMap.create!(
  :identifier => 98121,
  :option => o41
)

z394 = DomainMap.create!(
  :identifier => 98122,
  :option => o41
)

z395 = DomainMap.create!(
  :identifier => 98124,
  :option => o41
)

z396 = DomainMap.create!(
  :identifier => 98125,
  :option => o41
)

z397 = DomainMap.create!(
  :identifier => 98126,
  :option => o41
)

z398 = DomainMap.create!(
  :identifier => 98127,
  :option => o41
)

z399 = DomainMap.create!(
  :identifier => 98129,
  :option => o41
)

z400 = DomainMap.create!(
  :identifier => 98131,
  :option => o41
)

z401 = DomainMap.create!(
  :identifier => 98132,
  :option => o41
)

z402 = DomainMap.create!(
  :identifier => 98133,
  :option => o41
)

z403 = DomainMap.create!(
  :identifier => 98134,
  :option => o41
)

z404 = DomainMap.create!(
  :identifier => 98136,
  :option => o41
)

z405 = DomainMap.create!(
  :identifier => 98138,
  :option => o41
)

z406 = DomainMap.create!(
  :identifier => 98139,
  :option => o41
)

z407 = DomainMap.create!(
  :identifier => 98141,
  :option => o41
)

z408 = DomainMap.create!(
  :identifier => 98144,
  :option => o41
)

z409 = DomainMap.create!(
  :identifier => 98145,
  :option => o41
)

z410 = DomainMap.create!(
  :identifier => 98146,
  :option => o41
)

z411 = DomainMap.create!(
  :identifier => 98148,
  :option => o41
)

z412 = DomainMap.create!(
  :identifier => 98154,
  :option => o41
)

z413 = DomainMap.create!(
  :identifier => 98155,
  :option => o41
)

z414 = DomainMap.create!(
  :identifier => 98158,
  :option => o41
)

z415 = DomainMap.create!(
  :identifier => 98160,
  :option => o41
)

z416 = DomainMap.create!(
  :identifier => 98161,
  :option => o41
)

z417 = DomainMap.create!(
  :identifier => 98164,
  :option => o41
)

z418 = DomainMap.create!(
  :identifier => 98165,
  :option => o41
)

z419 = DomainMap.create!(
  :identifier => 98166,
  :option => o41
)

z420 = DomainMap.create!(
  :identifier => 98168,
  :option => o41
)

z421 = DomainMap.create!(
  :identifier => 98170,
  :option => o41
)

z422 = DomainMap.create!(
  :identifier => 98174,
  :option => o41
)

z423 = DomainMap.create!(
  :identifier => 98175,
  :option => o41
)

z424 = DomainMap.create!(
  :identifier => 98177,
  :option => o41
)

z425 = DomainMap.create!(
  :identifier => 98178,
  :option => o41
)

z426 = DomainMap.create!(
  :identifier => 98181,
  :option => o41
)

z427 = DomainMap.create!(
  :identifier => 98185,
  :option => o41
)

z428 = DomainMap.create!(
  :identifier => 98188,
  :option => o41
)

z429 = DomainMap.create!(
  :identifier => 98189,
  :option => o41
)

z430 = DomainMap.create!(
  :identifier => 98190,
  :option => o41
)

z431 = DomainMap.create!(
  :identifier => 98191,
  :option => o41
)

z432 = DomainMap.create!(
  :identifier => 98194,
  :option => o41
)

z433 = DomainMap.create!(
  :identifier => 98195,
  :option => o41
)

z434 = DomainMap.create!(
  :identifier => 98198,
  :option => o41
)

z435 = DomainMap.create!(
  :identifier => 98199,
  :option => o41
)

o42 = Option.create!(
  :name => 'Increased Vehicle License Fee',
  :short_name => 'Transportation Improvements',
  :description => 'The Seattle Transportation Benefit District\'s Proposition No. 1 concerns an increased Vehicle License Fee for transportation improvements.  If approved, this proposition would fund transportation facilities and services benefitting the City of Seattle, including: transportation system repairs, maintenance and safety improvements; transit improvements to increase speed, reliability and access; and pedestrian, bicycle and freight mobility programs, all as provided in STBD Resolution No. 5.  It would authorize a $60 increase in the Vehicle License Fee beginning in 2012, allowing collection of approximately $20.4 million annually for ten years.  Should this proposition be approved?',
  :domain => 'City of Seattle',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40328&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z436 = DomainMap.create!(
  :identifier => 98101,
  :option => o42
)

z437 = DomainMap.create!(
  :identifier => 98102,
  :option => o42
)

z438 = DomainMap.create!(
  :identifier => 98103,
  :option => o42
)

z439 = DomainMap.create!(
  :identifier => 98104,
  :option => o42
)

z440 = DomainMap.create!(
  :identifier => 98105,
  :option => o42
)

z441 = DomainMap.create!(
  :identifier => 98106,
  :option => o42
)

z442 = DomainMap.create!(
  :identifier => 98107,
  :option => o42
)

z443 = DomainMap.create!(
  :identifier => 98108,
  :option => o42
)

z444 = DomainMap.create!(
  :identifier => 98109,
  :option => o42
)

z445 = DomainMap.create!(
  :identifier => 98111,
  :option => o42
)

z446 = DomainMap.create!(
  :identifier => 98112,
  :option => o42
)

z447 = DomainMap.create!(
  :identifier => 98113,
  :option => o42
)

z448 = DomainMap.create!(
  :identifier => 98114,
  :option => o42
)

z449 = DomainMap.create!(
  :identifier => 98115,
  :option => o42
)

z450 = DomainMap.create!(
  :identifier => 98116,
  :option => o42
)

z451 = DomainMap.create!(
  :identifier => 98117,
  :option => o42
)

z452 = DomainMap.create!(
  :identifier => 98118,
  :option => o42
)

z453 = DomainMap.create!(
  :identifier => 98119,
  :option => o42
)

z454 = DomainMap.create!(
  :identifier => 98121,
  :option => o42
)

z455 = DomainMap.create!(
  :identifier => 98122,
  :option => o42
)

z456 = DomainMap.create!(
  :identifier => 98124,
  :option => o42
)

z457 = DomainMap.create!(
  :identifier => 98125,
  :option => o42
)

z458 = DomainMap.create!(
  :identifier => 98126,
  :option => o42
)

z459 = DomainMap.create!(
  :identifier => 98127,
  :option => o42
)

z460 = DomainMap.create!(
  :identifier => 98129,
  :option => o42
)

z461 = DomainMap.create!(
  :identifier => 98131,
  :option => o42
)

z462 = DomainMap.create!(
  :identifier => 98132,
  :option => o42
)

z463 = DomainMap.create!(
  :identifier => 98133,
  :option => o42
)

z464 = DomainMap.create!(
  :identifier => 98134,
  :option => o42
)

z465 = DomainMap.create!(
  :identifier => 98136,
  :option => o42
)

z466 = DomainMap.create!(
  :identifier => 98138,
  :option => o42
)

z467 = DomainMap.create!(
  :identifier => 98139,
  :option => o42
)

z468 = DomainMap.create!(
  :identifier => 98141,
  :option => o42
)

z469 = DomainMap.create!(
  :identifier => 98144,
  :option => o42
)

z470 = DomainMap.create!(
  :identifier => 98145,
  :option => o42
)

z471 = DomainMap.create!(
  :identifier => 98146,
  :option => o42
)

z472 = DomainMap.create!(
  :identifier => 98148,
  :option => o42
)

z473 = DomainMap.create!(
  :identifier => 98154,
  :option => o42
)

z474 = DomainMap.create!(
  :identifier => 98155,
  :option => o42
)

z475 = DomainMap.create!(
  :identifier => 98158,
  :option => o42
)

z476 = DomainMap.create!(
  :identifier => 98160,
  :option => o42
)

z477 = DomainMap.create!(
  :identifier => 98161,
  :option => o42
)

z478 = DomainMap.create!(
  :identifier => 98164,
  :option => o42
)

z479 = DomainMap.create!(
  :identifier => 98165,
  :option => o42
)

z480 = DomainMap.create!(
  :identifier => 98166,
  :option => o42
)

z481 = DomainMap.create!(
  :identifier => 98168,
  :option => o42
)

z482 = DomainMap.create!(
  :identifier => 98170,
  :option => o42
)

z483 = DomainMap.create!(
  :identifier => 98174,
  :option => o42
)

z484 = DomainMap.create!(
  :identifier => 98175,
  :option => o42
)

z485 = DomainMap.create!(
  :identifier => 98177,
  :option => o42
)

z486 = DomainMap.create!(
  :identifier => 98178,
  :option => o42
)

z487 = DomainMap.create!(
  :identifier => 98181,
  :option => o42
)

z488 = DomainMap.create!(
  :identifier => 98185,
  :option => o42
)

z489 = DomainMap.create!(
  :identifier => 98188,
  :option => o42
)

z490 = DomainMap.create!(
  :identifier => 98189,
  :option => o42
)

z491 = DomainMap.create!(
  :identifier => 98190,
  :option => o42
)

z492 = DomainMap.create!(
  :identifier => 98191,
  :option => o42
)

z493 = DomainMap.create!(
  :identifier => 98194,
  :option => o42
)

z494 = DomainMap.create!(
  :identifier => 98195,
  :option => o42
)

z495 = DomainMap.create!(
  :identifier => 98198,
  :option => o42
)

z496 = DomainMap.create!(
  :identifier => 98199,
  :option => o42
)

o43 = Option.create!(
  :name => 'Licensed Card Rooms in the City of Tukwila',
  :short_name => 'Card Rooms',
  :description => 'Tukwila Resolution No. 1745 submits the following question to the voters of the City of Tukwila regarding social card rooms in the City:\n\nShould gambling in the form of social card rooms be allowed in Tukwila?',
  :domain => 'City of Tukwila',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40326&eid=1249',
  :category => 'Advisory Measure',
  :designator => '1'
)

z497 = DomainMap.create!(
  :identifier => 98108,
  :option => o43
)

z498 = DomainMap.create!(
  :identifier => 98138,
  :option => o43
)

z499 = DomainMap.create!(
  :identifier => 98168,
  :option => o43
)

z500 = DomainMap.create!(
  :identifier => 98178,
  :option => o43
)

z501 = DomainMap.create!(
  :identifier => 98188,
  :option => o43
)

o44 = Option.create!(
  :name => 'Sales and Use Tax for Transportation Improvements',
  :short_name => 'Transportation Improvements',
  :description => 'he Board of North Bend Transportation Benefit District No. 1 has adopted Resolution No. 01-2011 concerning a proposition to finance transportation improvements.  This proposition would authorize a sales and use tax at a rate of two-tenths of one percent (.2%) of the selling price in the case of a sales tax, or value of article used in the case of a use tax, for a period not exceeding 10 years, and dedicate that tax to repaying North Bend Transportation Benefit District No. 1 indebtedness incurred to finance street and related improvements specified in Resolution No. 01-2011.  Should this proposition be approved? ',
  :domain => 'City of North Bend',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40327&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z502 = DomainMap.create!(
  :identifier => 98045,
  :option => o44
)

z503 = DomainMap.create!(
  :identifier => 98068,
  :option => o44
)

o45 = Option.create!(
  :name => 'Supplemental Levy to Support Class Size',
  :short_name => 'School Levy',
  :description => 'The Board of Directors of Shoreline School District No. 412 adopted Resolution No. 2011-14, concerning a supplemental levy to support class size.  This proposition would address impacts on class size due to State budget reductions by levying the following excess taxes, in addition to the existing levies for educational programs, maintenance and operations approved by the voters in February, 2010, on all taxable property within the District.\n\nPassage of Proposition No. 1 would allow the levy of $1,300,000 of property taxes within the Shoreline School District for collection in 2012, the levy of $1,400,000 of taxes for collection in 2013, and the levy of $1,500,000 in taxes for 2014. The purpose of the levy is to support class size in response to State budget reductions.  This supplemental levy is in addition to the maintenance and operation levy, approved by the voters in the February 2010 election, on all taxable property within the District.  The taxes approved by this proposition would be deposited in the Shoreline School District\'s General Fund and expended to support class size.  If authorized by the voters and based upon current assessed valuation information, the estimated levy rates per $1000 of assessed value would be $0.09 (2012 collection); $0.09 (2013 collection) and $0.10 (2014 collection).',
  :domain => 'City of Shoreline',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40329&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z504 = DomainMap.create!(
  :identifier => 98133,
  :option => o45
)

z505 = DomainMap.create!(
  :identifier => 98155,
  :option => o45
)

z506 = DomainMap.create!(
  :identifier => 98177,
  :option => o45
)

o46 = Option.create!(
  :name => 'Increasing Number of Commissioners',
  :short_name => 'Fire Dist Commission',
  :description => 'Shall the board of commissioners of King County Fire Protection District No. 28 be increased from three members to five members?',
  :domain => 'City of Enumclaw',
  :domain_short => 'city',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40330&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z507 = DomainMap.create!(
  :identifier => 98022,
  :option => o46
)

o47 = Option.create!(
  :name => 'Protection of Current Tax Levy from Prorationing',
  :short_name => 'Park Levy Allocation',
  :description => 'The Board of Directors of the Si View Metropolitan Park District adopted Resolution No. 2011-02 concerning protecting a portion of the existing property tax levy from being reallocated to other taxing districts, a process known as prorationing.  To maintain current operations, park district facilities and programs, including the Si View Community Center and Pool, parks, playfields, playgrounds, trails, adult programming, fitness and youth sports programs, summer camps, and after-school recreation programs for youth and teens, shall $0.25/$1,000 of assessed valuation of the District\'s current regular property tax levy be protected from prorationing under RCW 84.52.010(3)(b) for the tax years 2012 through 2017?',
  :domain => 'Si View Metropolitan Park District',
  :domain_short => 'district',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40331&eid=1249',
  :category => 'Proposition',
  :designator => '1'
)

z508 = DomainMap.create!(
  :identifier => 98045,
  :option => o47
)

z509 = DomainMap.create!(
  :identifier => 98065,
  :option => o47
)

z510 = DomainMap.create!(
  :identifier => 98068,
  :option => o47
)

o48 = Option.create!(
  :name => 'One-Year Operations and Maintenance Levy',
  :short_name => 'Parks Levy',
  :description => 'The Board of Directors of the Si View Metropolitan Park District adopted Resolution No. 2011-03 concerning a proposition for basic safety, maintenance and operations.  This proposition would maintain current operations, facilities and programs, including the Si View Community Center and Pool, parks, playfields, playgrounds, sports programs, trails, adult programming, summer camps, and after-school recreation programs for youth and teens, by authorizing the District to levy a one-year excess property tax levy on all taxable property within the District at an approximate rate of $0.21/$1,000 of assessed value to provide $462,000, to be collected in 2012.',
  :domain => 'Si View Metropolitan Park District',
  :domain_short => 'district',
  :url => 'http://your.kingcounty.gov/elections/contests/measureinfo.aspx?cid=40332&eid=1249',
  :category => 'Proposition',
  :designator => '2'
)

z511 = DomainMap.create!(
  :identifier => 98045,
  :option => o48
)

z512 = DomainMap.create!(
  :identifier => 98065,
  :option => o48
)

z513 = DomainMap.create!(
  :identifier => 98068,
  :option => o48
)

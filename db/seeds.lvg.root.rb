# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#


#TODO: replace these values with settings
admin = User.create!(
  :username => 'ConsiderIt Admin',
  :email => 'info@deployment.org',
  :password   => 'password',
  :password_confirmation => 'password'
)

# Confirm the user for Devise
# admin.confirm! 

o1 = Option.create!(
  :name => 'liquor (beer, wine and spirits)',
  :short_name => 'liquor',
  :description => 'This measure would direct the liquor control board to close all state liquor stores; terminate contracts with private stores selling liquor; and authorize the state to issue licenses that allow spirits (hard liquor) to be sold, distributed, and imported by private parties.\nIt would repeal uniform pricing and certain other requirements governing business operations for distributors and producers of beer and wine.\nStores that held contracts to sell spirits could convert to liquor retailer licenses.',
  #:short_description => 'This measure would close state liquor stores; authorize sale, distribution, and importation of spirits by private parties; and repeal certain requirements that govern the business operations of beer and wine distributors and producers.',
  :image => '',
  :url => 'http://www.sos.wa.gov/elections/initiatives/text/i1100.pdf',
  :category => 'Initiative',
  :designator => '1100'
)

Point.create!(
  :option => o1,
  :user => admin,
  :is_pro => true,
  :nutshell => 'Government shouldn\'t be involved in the sales of liquor',
  :text => ''
)

Point.create!(
  :option => o1,
  :user => admin,
  :is_pro => false,
  :nutshell => 'This could inadvertently result in more advertising to minors about liquor because we will now see liquor ads in more places.',
  :text => ''
)



o2 = Option.create!(
  :name => 'liquor (beer, wine and spirits)',
  :short_name => 'liquor',
  :description => 'This measure would direct the liquor control board to close all state liquor stores and to license qualified private parties as spirits (hard liquor) retailers or distributors.\\nIt would require licensees to pay the state a percentage of their first five years of gross spirits sales; repeal certain taxes on retail spirits sales; direct the board to recommend to the legislature a tax to be paid by spirits distributors; and revise other laws concerning spirits.',
  #:short_description => 'This measure would close all state liquor stores and license private parties to sell or distribute spirits. It would revise laws concerning regulation, taxation and government revenues from distribution and sale of spirits.',
  :image => '',
  :url => 'http://www.sos.wa.gov/elections/initiatives/text/i1105.pdf',
  :category => 'Initiative',
  :designator => '1105'
)

Point.create!(
  :option => o2,
  :user => admin,
  :is_pro => true,
  :nutshell => 'Government shouldn\'t be involved in the sales of liquor',
  :text => ''
)

Point.create!(
  :option => o2,
  :user => admin,
  :is_pro => false,
  :nutshell => 'There may be a larger regulation burden on small business than anticipated.',
  :text => ''
)


o3 = Option.create!(
  :name => 'reversing certain 2010 amendments to state tax laws',
  :short_name => 'state tax laws',
  :description => 'This measure would reverse certain 2010 amendments to state tax laws, thereby ending the sales tax on candy and the temporary sales tax on some bottled water; and ending temporary excise taxes on the activity of selling certain carbonated beverages, not including alcoholic beverages or carbonated bottled water.\nIt would also reinstate a reduced business and occupation tax rate for processors of certain foods.',
  #:short_description => 'This measure would end sales tax on candy; end temporary sales tax on some bottled water; end temporary excise taxes on carbonated beverages; and reduce tax rates for certain food processors.',
  :image => '',
  :url => 'http://www.sos.wa.gov/elections/initiatives/text/i1107.pdf',
  :category => 'Initiative',
  :designator => '1107'
)

Point.create!(
  :option => o3,
  :user => admin,
  :is_pro => true,
  :nutshell => 'Sin taxes and other forms of government interference with behavior never work well.',
  :text => ''
)

Point.create!(
  :option => o3,
  :user => admin,
  :is_pro => false,
  :nutshell => 'Our state is in desperate need of additional revenue and these sorts of optional taxes are a great way to get it.',
  :text => ''
)

o4 = Option.create!(
  :name => 'tax and fee increases imposed by state government',
  :short_name => 'tax increases',
  :description => 'This measure would restate the existing statutory requirement that any action or combination of actions by the legislature that raises taxes must be approved by a two-thirds vote in both houses of the legislature or approved in a referendum to the people, and it would restate the existing statutory definition of "raises taxes."\nIt would also restate that new or increased fees must be approved by a majority vote in both houses of the legislature.',
  #:short_description => 'This measure would restate existing statutory requirements that legislative actions raising taxes must be approved by two-thirds legislative majorities or receive voter approval, and that new or increased fees require majority legislative approval.',
  :image => '',
  :url => 'http://www.sos.wa.gov/elections/initiatives/text/i1053.pdf',
  :category => 'Initiative',
  :designator => '1053'
)

Point.create!(
  :option => o4,
  :user => admin,
  :is_pro => true,
  :nutshell => 'This sets a higher threshold for the legislature to meet before increasing taxes on citizens that already pay enough as it is.',
  :text => ''
)

Point.create!(
  :option => o4,
  :user => admin,
  :is_pro => false,
  :nutshell => 'This further limits the legislatures ability to control the state budget process, which is part of why we are having so many funding issues already.',
  :text => ''
)

o5 = Option.create!(
  :name => 'industrial insurance',
  :short_name => 'industrial insurance',
  :description => 'This measure would permit certification of private insurers as industrial insurance insurers, and authorize employers to purchase state-mandated industrial insurance coverage through an \"industrial insurance insurer\" beginning July 1, 2012.\\nIt would establish a joint legislative task force to propose legislation conforming current statutes to this measure\xE2\x80\x99s provisions, and would direct the legislature to enact such supplemental conforming legislation as necessary by March 1, 2012.\\nIt would also eliminate the worker-paid share of medical-benefit premiums.',
  #:short_description => 'This measure would authorize employers to purchase private industrial insurance beginning July 1, 2012; direct the legislature to enact conforming legislation by March 1, 2012; and eliminate the worker-paid share of medical-benefit premiums.',
  :image => '',
  :url => 'http://www.sos.wa.gov/elections/initiatives/text/i1082.pdf',
  :category => 'Initiative',
  :designator => '1082'
)

Point.create!(
  :option => o5,
  :user => admin,
  :is_pro => true,
  :nutshell => 'This will create more competition in the market, hopefully leading to lower costs.',
  :text => ''
)

Point.create!(
  :option => o5,
  :user => admin,
  :is_pro => false,
  :nutshell => 'With the entire burden of paying for them on the state, there is a potential that some workers could lose certain benefits.',
  :text => ''
)


o6 = Option.create!(
  :name => 'establishing a state income tax and reducing other taxes',
  :short_name => 'state income tax',
  :description => 'This measure would establish a tax on \"adjusted gross income\" (as determined under the federal internal revenue code) above $200,000 for individuals and $400,000 for married couples or domestic partners filing jointly; reduce the limit on statewide property taxes by 20%; and increase the business and occupation tax credit to $4,800. \\nThe tax revenues would replace revenues lost from the reduced levy and increased credit; remaining revenues would be directed to education and health services.',
  #:short_description => 'This measure would tax \xE2\x80\x9Cadjusted gross income\xE2\x80\x9D above $200,000 (individuals) and $400,000 (joint-filers), reduce state property tax levies, reduce certain business and occupation taxes, and direct any increased revenues to education and health.',
  :image => '',
  :url => 'http://www.sos.wa.gov/elections/initiatives/text/i1098.pdf',
  :category => 'Initiative',
  :designator => '1098'
)

Point.create!(
  :option => o6,
  :user => admin,
  :is_pro => true,
  :nutshell => 'This will guarantee much needed funding for basic health and education in our state.',
  :text => ''
)

Point.create!(
  :option => o6,
  :user => admin,
  :is_pro => false,
  :nutshell => 'This is just the first step to a state income tax for all Washingtonians.',
  :text => ''
)

o7 = Option.create!(
  :name => 'funding bonds for energy efficiency projects in schools',
  :short_name => 'bond bill',
  :description => 'The legislature has passed Engrossed House Bill No. 2561, concerning authorizing and funding bonds for energy efficiency projects in schools.\\nThis bill would authorize bonds to finance construction and repair projects increasing energy efficiency in public schools and higher education buildings, and continue the sales tax on bottled water otherwise expiring in 2013.',
  #:short_description => 'This bill would authorize bonds to finance construction and repair projects increasing energy efficiency in public schools and higher education buildings, and continue the sales tax on bottled water otherwise expiring in 2013.',
  :image => '',
  :url => 'http://wei.secstate.wa.gov/osos/en/PreviousElections/2010/general/Documents/EHB%202561%20complete%20text.pdf',
  :category => 'Referendum Bill',
  :designator => '52'
)

Point.create!(
  :option => o7,
  :user => admin,
  :is_pro => true,
  :nutshell => 'We need more funding for our state schools.',
  :text => ''
)

Point.create!(
  :option => o7,
  :user => admin,
  :is_pro => false,
  :nutshell => 'We already pay enough in taxes and schools need to learn to be more efficient in spending their existing funding.',
  :text => ''
)

o8 = Option.create!(
  :name => 'limiting state debt',
  :short_name => 'debt limit',
  :description => 'The legislature has proposed a constitutional amendment concerning the limitation on state debt.\\nThis amendment would require the state to reduce the interest accounted for in calculating the constitutional debt limit, by the amount of federal payments scheduled to be received to offset that interest.',
  #:short_description => 'This amendment would require the state to reduce the interest accounted for in calculating the constitutional debt limit, by the amount of federal payments scheduled to be received to offset that interest.',
  :image => '',
  :url => 'http://wei.secstate.wa.gov/osos/en/PreviousElections/2010/general/Documents/SJR%208225%20complete%20text.pdf',
  :category => 'Resolution',
  :designator => '8225'
)

Point.create!(
  :option => o8,
  :user => admin,
  :is_pro => true,
  :nutshell => 'This will reduce the cost to state taxpayers by reducing the net interest rate paid on General Obligation Bonds issued by the State.',
  :text => ''
)

Point.create!(
  :option => o8,
  :user => admin,
  :is_pro => false,
  :nutshell => 'This will allow the state to take on more debt than it can reasonably afford to pay back at a time when we are already in fiscal trouble.',
  :text => ''
)


o9 = Option.create!(
  :name => 'denying bail for persons charged with certain crimes',
  :short_name => 'bail denial',
  :description => 'The legislature has proposed a constitutional amendment on denying bail for persons charged with certain criminal offenses.\\nThis amendment would authorize courts to deny bail for offenses punishable by the possibility of life in prison, on clear and convincing evidence of a propensity for violence that would likely endanger persons.',
  #:short_description => 'This amendment would authorize courts to deny bail for offenses punishable by the possibility of life in prison, on clear and convincing evidence of a propensity for violence that would likely endanger persons.',
  :image => '',
  :url => 'http://wei.secstate.wa.gov/osos/en/PreviousElections/2010/general/Documents/ESHJR%204220%20complete%20text.pdf',
  :category => 'Resolution',
  :designator => '4220'
)

Point.create!(
  :option => o9,
  :user => admin,
  :is_pro => true,
  :nutshell => 'This reduces judicial discretion in setting bail, making sure no violent offenders are on the streets.',
  :text => ''
)

Point.create!(
  :option => o9,
  :user => admin,
  :is_pro => false,
  :nutshell => 'This reduces judicial discretion in setting bail, taking away too much freedom from judges.',
  :text => ''
)






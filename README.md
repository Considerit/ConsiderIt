<a href="https://consider.it/">![Logo](https://cdn.rawgit.com/tkriplean/ConsiderIt/master/public/logo.svg)</a>

[Consider.it][1] is a web-based discussion system that creates civil, organized, and efficient online dialogue by visually summarizing what your community thinks and why. It helps focus discussion even when lots of people participate.

[1]: <https://consider.it>

Consider.it has been used in a variety of contexts, including: 
- public engagement between cities and citizens
- ideation and deliberation platform for open source communities
- participatory strategic planning for non-profits and political organizing
- decision making support for cohousing communities
- aide for teaching critical thinking in k-12 classrooms
- academics peer reviewing articles before publication
- debating tv shows

The creator and maintainer is [Travis Kriplean](https://github.com/tkriplean/). Travis invented Consider.it in the course of his PhD work on supporting reflective public dialogue at the University of Washington, after which he went indie and bootstrapped his continued efforts to create technology that helps people listen to each other. 

To learn more, [visit Consider.it][1].

License
-------

Consider.it is an open source product released under the GNU Affero General Public License v3. This is a copyleft license that considers hosting code on a server a form of distribution. See the [COPYING file](COPYING) or [read background about the AGPL](https://www.gnu.org/licenses/why-affero-gpl.en.html). 

Because Consider.it LLC retains permission to relicense the Consider.it source code, we can [dual license](https://en.wikipedia.org/wiki/Multi-licensing) the source code to you under a license other than AGPL. Reach out to [travis@consider.it](travis@consider.it) to discuss. Interested in integrating Consider.it into the bowels of other products, as well as supporting other Consider.it businesses explore different markets, both of which will almost certainly require a different license. 

On the state of Consider.it
---------------------------

Consider.it was open sourced after several years of being closed source. And it is mostly just my code. Unfortunate consequences include: inconsistant styling, some hardcoding to production environment, substandard documentation, obscure commit messages, hardcoded references to specific customers, leaky abstractions, lack of releases and versioning, and a lack of tests. Sorry!

I'm also working on next generation prototypes that build on what we've learned over the past five years applying Consider.it, and eventually be merged back here. The next Considerit will be more general (right now, it forces a structure of lists of proposals, with each proposal having pros/cons and each pro or con having comments), and the structure will be modifiable as a conversation progresses so that facilitators can use the best structure for the situation. The "Slidergram" widget will also be factored out and generalized. 

The roadmap is:
1. Refactor to a more generalized and recursive point/opinion data model, subsuming "proposals", "points", and "comments"
2. Eliminate "crafting view" for creating a position and make it lists of points+sliders through and through
3. Design & develop user contributions <---> profile/reputation <---> notifications value loop

There are other developments I'm interested in (Slack integration, analytics dashboard, verified accounts, Blockchain backed data, etc) but I believe the above are more important for the platform.  

Built on
--------

- [Ruby on Rails](http://rubyonrails.org/) — Our back end is a Rails app. It is possible that we will move to a pure Javascript stack. 
- [Statebus.js](https://stateb.us/) – Statebus provides reactive state management. We use an early client-only version of Statebus called ActiveREST. 
- [React.js](https://facebook.github.io/react/) – Our front end is a Statebus-wrapped version of React.js.
- [MySQL](https://www.mysql.com/) — MySQL is our database.


Developer installation
---------------------

See (and improve?) the [development installation guide](docs/developer_installation_guide.md).

Deployment guide
----------------

Missing! If you're trying to deploy, reach out to [travis@consider.it](travis@consider.it) for support, and we'll work together to create a guide. 

Contributing
------------

Time permitting, Travis would like collaborate with you! Well, as long as you are a [considerate human being](docs/code-of-conduct.md). 

Note that there are still lots of todos to lower the barrier to making contributions, such as identifying good first-time projects. In the meantime, please be patient! And if you want to be a brave, early helper, please reach out to [travis@consider.it](travis@consider.it).

Note that if you want your pull requests to be merged, you'll first have to agree to a Contributor License Agreement. This gives me the option to dual license Consider.it in the future, while you retain your rights to your contribution.

require './features'

window.Tour = ReactiveComponent
  displayName: 'Tour'

  render: -> 


    DIV null,

      DIV 
        style: 
          textAlign: 'center'
          paddingTop: 48        
          position: 'relative'
          top: 8

        IMG 
          src: asset('product_page/tour_demo_death_star.png')
          style: 
            width: 800
            height: 453
            borderRadius: '4px 4px 0 0'

      DIV 
        style: 
          position: 'relative'
          zIndex: 2
          backgroundColor: 'white'
          boxShadow: '0px -17px 27px 0px rgba(0,0,0,.14)'
          paddingTop: 30
          paddingBottom: 70

        DIV 
          style: 
            width: SAAS_PAGE_WIDTH
            margin: 'auto'


          DIV 
            style: 
              maxWidth: 765 
              margin: 'auto'

            H1 
              style: _.extend {}, h1,
                color: '#303030'  
                textAlign: 'center'              

              "The only forum to visually summarize what your community thinks and why"


            DIV 
              style: 
                margin: 'auto'
                maxWidth: 700
                marginTop: 40
              DIV 
                style: 
                  fontWeight: 200
                  fontSize: 28
                  color: '#303030'
                  fontStyle: 'italic'
                "We had a nearly 50/50 deadlocked split in our co-housing community. After we started using Consider.it, people could clearly express the reasons behind their opinions, and see other’s reasons. We were able to work out a compromise. That's the first time where I felt like democracy was actually working."
              
              DIV
                style: 
                  fontSize: 18
                  color: '#303030'
                  textAlign: 'right'
                'Pierre-Elouan Réthoré'          

          Features()
          Research()     



window.Research = -> 

  # | 323666 | Travis Kriplean, PhD, Computer Science, University of Washington                |
  # | 324669 | Deen Freelon, Assistant Professor of Communication Studies, American University |
  # | 324670 | Alan Borning, Professor of Computer Science, University of Washington           |
  # | 324671 | Lance Bennett, Professor of Political Science, University of Washington         |
  # | 324672 | Jonathan Morgan, PhD, Human Centered Design, University of Washington           |
  # | 324673 | Caitlin Bonnar, Computer Science, University of Washington                      |
  # | 324674 | Brian Gill, Professor of Statistics, Seattle Pacific University                 |
  # | 324675 | Bo Kinney, Librarian, Seattle Public Library                                    |
  # | 324678 | Menno De Jong, Professor of Behavioral Sciences, University of Twente           |
  # | 324679 | Hans Stiegler, Behavioral Sciences, University of Twente                        |

  authors = (author_list) -> 
    DIV 
      style:
        position: 'absolute'
        top: 5
        right: -40

      UL 
        style:
          display: 'inline'

        for author,idx in author_list
          LI 
            key: idx
            style: 
              display: 'inline-block'
              listStyle: 'none'
              zIndex: 10 - idx
              position: 'absolute'
              left: 25 * idx
              top: 25 * idx

            Avatar
              key: "/user/#{author}"
              user: "/user/#{author}"
              img_size: 'large'
              style: 
                width: 50
                height: 50


  papers = [
    {
      url: "http://dub.washington.edu/djangosite/media/papers/kriplean-cscw2012.pdf"
      title: 'Supporting Reflective Public Thought with Consider.it'
      venue: '2012 ACM Conference on Computer Supported Cooperative Work'
      authors: [323666, 324672, 324669, 324670, 324671]
    },    {
      url: "https://dl.dropboxusercontent.com/u/3403211/papers/jitp.pdf"
      title: 'Facilitating Diverse Political Engagement'
      venue: 'Journal of Information Technology & Politics, Volume 9, Issue 3'
      authors: [324669, 323666, 324672, 324671, 324670]
    },    {
      url: "http://homes.cs.washington.edu/~borning/papers/kriplean-cscw2014.pdf"
      title: 'On-demand Fact-checking in Public Dialogue'
      venue: '2014 ACM Conference on Computer Supported Cooperative Work'
      authors: [324673, 323666, 324670, 324675, 324674]
    },    {
      url: "http://www.sciencedirect.com/science/article/pii/S0747563215003891"
      title: 'Facilitating Personal Deliberation Online: Immediate Effects of Two Consider.it Variations'
      venue: 'Forthcoming, Computers in Human Behavior, Volume 51, Part A'
      authors: [324679, 324678]
    }
  ]

  DIV 
    style: 
      width: SAAS_PAGE_WIDTH
      margin: '80px auto'

    H1
      style: _.extend {}, h1, 
        margin: '20px'

      'Academic research about Consider.it'

    UL
      style: 
        listStyle: 'none'
        width: TEXT_WIDTH - 50
        position: 'relative'
        left: '50%'
        marginLeft: -TEXT_WIDTH / 2 - 50

      for paper in papers
        LI 
          key: paper.title
          style: 
            padding: '16px 32px'
            position: 'relative'
            backgroundColor: considerit_gray
            boxShadow: '#b5b5b5 0 1px 1px 0px'
            borderRadius: 32
            marginBottom: 20

          A 
            style:  _.extend {}, a, base_text
            href: paper.url
            paper.title
          DIV 
            style: _.extend {}, small_text
            paper.venue

          DIV
            style: css.crossbrowserify
              transform: 'rotate(90deg)'
              position: 'absolute'
              right: -27
              top: 20

            Bubblemouth 
              apex_xfrac: 0
              width: 30
              height: 30
              fill: considerit_gray
              stroke: 'transparent'
              stroke_width: 0
              box_shadow:   
                dx: '3'
                dy: '0'
                stdDeviation: "2"
                opacity: .5


          authors paper.authors

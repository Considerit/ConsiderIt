// You can fiddle with these variables

function mini_histo(width, height, parent, opinions) {
    width = width || 400
    height = height || 70

    // Big power, slow
    var n = 35,           // Number of opinions
        r = 10,           // Size of each avatar
        fade_in_time = 0,
        x_force_mult = 2,
        y_force_mult = 1,
        ratio_filled = .3,
        targets = 'power'

    // (2*r)^2 * length == width * height * ratio_filled
    // (width * height / length) * 2 = (2*r)^2
    // sqrt(width * height / length * 2) = r
    r = Math.sqrt(width * height / opinions.length * ratio_filled)/2
    r = Math.min(r, width/2, height/2)
    if (opinions.length > 0) {
        // Now round r up until it fits perfectly within height
        var times_fit = height / (2*r)
        r = (height / (Math.floor(times_fit))) / 2 - .001
    }
    function x_target(i) {
        var x = i / n

        return (opinions[i].stance + 1)/2 * width

        // if (targets == 'power')
        //     return r + (x * x * width) * ((width - 2*r) / width)

        // else if (targets == 'stacks') {
        //     var num_stacks = 10
        //     return r + (Math.ceil((i / n) * num_stacks) * (width-r-r)) / num_stacks
        // }
    }
    
    //var svg = d3.select(parent).append("svg")
    var fill = d3.scale.category10()
    var color = d3.scale.linear()
        .domain([0, 10, 20])
        //.range(["#755", '#fff', "#575"])
        //.range(["red", '#fff', "green"])
        .range(["#555", '#fff', "#555"])
        .interpolate(d3.interpolateLab);
    var nodes
    var node
    var force
    var opinions = opinions.slice().sort(function (a,b) {return a.stance-b.stance})
    n = opinions.length

    function init() {
        // svg.attr('width', width)
        //     .attr('height', height)
        //     .style("opacity", 1e-6)
        //     .transition()
        //     .duration(fade_in_time)
        //     .style("opacity", 1)

        nodes = d3.range(opinions.length).map(function(i) {
            //return {index: i, radius: r, x: x_target(i), y: height};
            return {index: i, radius: r,
                    x: r + (width-r-r) * (i / n),
                    //x: r + Math.random() * (width - r - r),  // With random
                    y: r + Math.random() * (height - r-r)// r + (i * 400 / n) % (height-r-r)
                   }
        })

        force = d3.layout.force()
            .nodes(nodes)
        //.size([width, height])
            .on("tick", tick)
            .on('end', function () {console.log('simulation complete')})
            .gravity(0)
            .charge(0)
            .chargeDistance(0)
        //.friction(-.1)
            .start()
        //.alpha(.02)

        // if (node)
        //     svg.selectAll('.node').remove()

        node = d3.select(parent).selectAll("img")
            .data(nodes)
            .call(force.drag)
            .on("mousedown", function() { d3.event.stopPropagation() })
            .on('dragstart', function () { force.alpha(.03) })
            // .enter().append("circle")
            // .attr("class", "node")
            // .attr("cx", function(d) { return d.x })
            // .attr("cy", function(d) { return d.y })
            // .attr("r", r)
            // //.style("fill", function(d, i) { return color(20 - i / n * 20) })
            // .style("fill", function(d, i) { 
            //     return color((opinions[i].stance / 2 + .5) * 20) })
            // .style("stroke", function(d, i) {
            //     return Math.abs(opinions[i].stance) < .2 && '#ccc' }) //d3.rgb(fill(1)).darker(2) })

        for (var i=0; i<opinions.length; i++)
            opinions[i].icon.style.width = opinions[i].icon.style.height = r*2 + 'px'
            
    }
    init()

    //d3.select("body").on("mousedown", scatter)


    function tick(e) {
        // Collision detection
        var q = d3.geom.quadtree(nodes),
            i = 0,
            n = nodes.length

        while (++i < n)
            q.visit(collide(nodes[i]))

        // Apply forces and stuff
        nodes.forEach(function(o, i) {

            // Move for NaNs
            if (isNaN(o.y) || isNaN(o.x)) {
                console.error('Nan0 at', o.x, o.y)
                o.y = height/2
                o.x = x_target(o.index)//width/2
            }

            // Apply forces
            // var time_scale = Math.min(.01 * t++, 1)
            // var k = time_scale * e.alpha
            o.x += e.alpha * (x_force_mult * width  * .001) * (x_target(o.index) - o.x)
            o.y += e.alpha * y_force_mult

            // Clip to bounding box
            o.x = Math.max(r, Math.min(width  - r, o.x))
            o.y = Math.max(r, Math.min(height - r, o.y))

            // Draw
            opinions[i].icon.style.left = o.x - r + 'px'
            opinions[i].icon.style.top  = o.y - r + 'px'
        })
                      
        // node.attr("cx", function(d) { return d.x })
        //     .attr("cy", function(d) { return d.y })
    }

    function collide(node) {
        var r = node.radius + 16,
            nx1 = node.x - r,
            nx2 = node.x + r,
            ny1 = node.y - r,
            ny2 = node.y + r
        return function(quad, x1, y1, x2, y2) {
            if (quad.point && (quad.point !== node)) {
                var x = node.x - quad.point.x,
                    y = node.y - quad.point.y,
                    l = Math.sqrt(x * x + y * y),
                    r = node.radius + quad.point.radius
                if (l < r) {
                    l = (l - r) / l * .5
                    node.x -= x *= l
                    node.y -= y *= l
                    quad.point.x += x
                    quad.point.y += y
                }
            }
            return x1 > nx2
                || x2 < nx1
                || y1 > ny2
                || y2 < ny1
        }
    }
}

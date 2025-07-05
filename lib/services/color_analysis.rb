#!/usr/bin/env ruby

require 'find'
require 'json'
require 'csv'
require 'set'

# Color Analysis Tool for ConsiderIt
# This script extracts all colors used throughout the codebase and groups them by similarity

class ColorAnalyzer
  COLOR_PATTERNS = {
    # Hex colors: #fff, #ffffff, #123456, #12345678 (with alpha)
    hex: /#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b/,
    
    # RGB/RGBA: rgb(255,255,255), rgba(0,0,0,0.5)
    rgb: /rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+))?\s*\)/,
    
    # HSL/HSLA: hsl(0,0%,100%), hsla(0,0%,0%,0.5)
    hsl: /hsla?\(\s*(\d+)\s*,\s*(\d+)%\s*,\s*(\d+)%\s*(?:,\s*([\d.]+))?\s*\)/,
    
    # Named colors in quotes or as bare words
    named: /\b(transparent|black|white|red|green|blue|yellow|orange|purple|pink|brown|gray|grey|darkred|darkgreen|darkblue|navy|maroon|olive|lime|aqua|teal|silver|fuchsia|magenta|cyan|gold|indigo|violet|tan|beige|khaki|lavender|coral|salmon|crimson|turquoise|plum|orchid|chocolate|peru|sienna|tomato|wheat|snow|ivory|linen|honeydew|azure|aliceblue|ghostwhite|whitesmoke|seashell|oldlace|floralwhite|lightgray|lightgrey|gainsboro|darkgray|darkgrey|dimgray|dimgrey|lightslategray|lightslategrey|slategray|slategrey|darkslategray|darkslategrey|indianred)\b/i
  }

  # Named color to hex mapping
  NAMED_COLORS = {
    'transparent' => 'transparent',
    'black' => '#000000',
    'white' => '#ffffff',
    'red' => '#ff0000',
    'green' => '#008000',
    'blue' => '#0000ff',
    'yellow' => '#ffff00',
    'orange' => '#ffa500',
    'purple' => '#800080',
    'pink' => '#ffc0cb',
    'brown' => '#a52a2a',
    'gray' => '#808080',
    'grey' => '#808080',
    'darkred' => '#8b0000',
    'darkgreen' => '#006400',
    'darkblue' => '#00008b',
    'navy' => '#000080',
    'maroon' => '#800000',
    'olive' => '#808000',
    'lime' => '#00ff00',
    'aqua' => '#00ffff',
    'teal' => '#008080',
    'silver' => '#c0c0c0',
    'fuchsia' => '#ff00ff',
    'magenta' => '#ff00ff',
    'cyan' => '#00ffff',
    'gold' => '#ffd700',
    'indigo' => '#4b0082',
    'violet' => '#ee82ee',
    'tan' => '#d2b48c',
    'beige' => '#f5f5dc',
    'khaki' => '#f0e68c',
    'lavender' => '#e6e6fa',
    'coral' => '#ff7f50',
    'salmon' => '#fa8072',
    'crimson' => '#dc143c',
    'turquoise' => '#40e0d0',
    'plum' => '#dda0dd',
    'orchid' => '#da70d6',
    'chocolate' => '#d2691e',
    'peru' => '#cd853f',
    'sienna' => '#a0522d',
    'tomato' => '#ff6347',
    'wheat' => '#f5deb3',
    'snow' => '#fffafa',
    'ivory' => '#fffff0',
    'linen' => '#faf0e6',
    'honeydew' => '#f0fff0',
    'azure' => '#f0ffff',
    'aliceblue' => '#f0f8ff',
    'ghostwhite' => '#f8f8ff',
    'whitesmoke' => '#f5f5f5',
    'seashell' => '#fff5ee',
    'oldlace' => '#fdf5e6',
    'floralwhite' => '#fffaf0',
    'lightgray' => '#d3d3d3',
    'lightgrey' => '#d3d3d3',
    'gainsboro' => '#dcdcdc',
    'darkgray' => '#a9a9a9',
    'darkgrey' => '#a9a9a9',
    'dimgray' => '#696969',
    'dimgrey' => '#696969',
    'lightslategray' => '#778899',
    'lightslategrey' => '#778899',
    'slategray' => '#708090',
    'slategrey' => '#708090',
    'darkslategray' => '#2f4f4f',
    'darkslategrey' => '#2f4f4f',
    'indianred' => '#cd5c5c'
  }

  # Colors to ignore in the analysis (e.g., site-specific overrides, deprecated colors)
  IGNORED_COLORS = [
    '#073682',  # Aeroparticipa theme override color
    '#3C5997', #stray facebook color
    '#008080' # seattle banner
  ]

  # Usage pattern detection regexes
  USAGE_PATTERNS = {
    # Variable definition pattern - must be first to prevent double recording
    # Matches both direct hex assignments and variable-to-variable assignments
    variable_definition: /window\.[\w_]+\s*=\s*(?:(['"]#[0-9a-fA-F]{3,8}['"])|(['"](?:black|white|red|green|blue|yellow|orange|purple|pink|brown|gray|grey)['"])|(\w+))/i,
    # Icon function patterns - flexible to handle 2 or 3 parameters
    icon: /(?:[\w_]*_?icon|Icon)\s+(?:[^,\n]*,\s*)*(['"]?[#\w]+['"]?)|(?:[\w_]*_?icon|Icon)\s*\([^)]*(['"]?[#\w]+['"]?)\s*\)/i,
    # Background with flexible matching for complex conditional expressions
    background: /(?:background-color|backgroundColor|background)\s*:\s*([^;,\}\n]+)/i,
    # Text color with flexible matching for complex conditional expressions  
    text: /(?:^|[^-\w])color\s*:\s*([^;,\}\n]+)/i,
    # Border with flexible matching for complex conditional expressions
    border: /(?:border(?:-(?:top|right|bottom|left))?(?:-color)?|borderColor|borderTop|borderRight|borderBottom|borderLeft|border-(?:top|right|bottom|left)-color)\s*:\s*([^;,\}\n]+)/i,
    shadow: /(?:box-shadow|boxShadow|text-shadow|textShadow|drop-shadow|filter)[\s:]*([^;,\}\n]*)/i,
    fill: /(?:fill\s*[:=]\s*|fillStyle\s*=\s*|<[^>]*fill\s*=\s*['"]?)([^;,\}\n]+)/i,
    stroke: /(?:stroke\s*[:=]\s*|strokeStyle\s*=\s*|<[^>]*stroke\s*=\s*['"]?)([^;,\}\n]+)/i,
    outline: /(?:outline|outline-color|outlineColor)\s*:\s*([^;,\}\n]+)/i,
    svg_element: /<(?:circle|rect|path|line|polygon|ellipse)[^>]*(?:fill|stroke)\s*=\s*['"]([^'"]+)['"]/i,
    gradient: /(?:linear-gradient|radial-gradient)\s*\([^)]*([#\w]+)/i,
    function_parameter: /\w+\s+[^,()]*,\s*(['"]?[#\w]+['"]?)\s*[,)]/i,
    config_property: /[\w_]+:\s*(['"]?[#\w]+['"]?)\s*[,\}]/i,
    opacity: /opacity\s*:\s*([^;,\}\n]+)/i,
    transform: /transform\s*:\s*([^;,\}\n]*)/i,
    filter: /filter\s*:\s*([^;,\}\n]*)/i
  }

  def initialize(root_path)
    @root_path = root_path
    @colors_found = {}
    @file_extensions = %w[.coffee .css .js .scss .sass]
    @color_variables = load_color_variables
  end

  def load_color_variables
    variables = {}
    variable_references = {}
    
    # First pass: Scan all .coffee files for color variable definitions
    Find.find(@root_path) do |path|
      next if File.directory?(path)
      next unless path.end_with?('.coffee')
      next if skip_file?(path)
      
      begin
        content = File.read(path, encoding: 'UTF-8')
        content.each_line do |line|
          # Match patterns like: window.success_color = "#81c765" or window.text_gray = '#444'
          # Also handle named colors like: window.text_dark = 'black'
          if match = line.match(/window\.(\w+)\s*=\s*['"]([^'"]+)['"]/)
            variable_name = match[1]
            color_value = match[2]
            
            # Handle hex colors
            if color_value.start_with?('#')
              normalized_color = normalize_hex(color_value)
            # Handle named colors
            elsif NAMED_COLORS.key?(color_value.downcase)
              normalized_color = NAMED_COLORS[color_value.downcase]
            else
              normalized_color = nil
            end
            
            if normalized_color
              # Store both the original and any overrides
              # For focus_color, we'll track both #456ae4 and #073682
              if variables[variable_name] && variable_name == 'focus_color'
                # Keep both values for focus_color as it has an override
                variables["#{variable_name}_original"] = variables[variable_name]
                variables["#{variable_name}_override"] = normalized_color
              end
              variables[variable_name] = normalized_color
            end
          # Match patterns like: window.default_avatar_in_histogram_color = bg_light_gray
          elsif match = line.match(/window\.(\w+)\s*=\s*(\w+)/)
            variable_name = match[1]
            reference_name = match[2]
            # Store this for later resolution
            variable_references[variable_name] = reference_name
          end
        end
      rescue => e
        # Skip files that can't be read
      end
    end
    
    # Second pass: Resolve variable references
    variable_references.each do |variable_name, reference_name|
      if variables[reference_name]
        variables[variable_name] = variables[reference_name]
      end
    end
    
    # Third pass: Check for function definitions that return colors
    Find.find(@root_path) do |path|
      next if File.directory?(path)
      next unless path.end_with?('.coffee')
      next if skip_file?(path)
      
      begin
        content = File.read(path, encoding: 'UTF-8')
        content.each_line do |line|
          # Match patterns like: window.focus_color = -> focus_color
          if match = line.match(/window\.(\w+)\s*=\s*->\s*(\w+)/)
            function_name = match[1]
            target_variable = match[2]
            if variables[target_variable]
              variables[function_name] = variables[target_variable]
              variables["#{function_name}()"] = variables[target_variable]
            end
          end
        end
      rescue => e
        # Skip files that can't be read
      end
    end
    
    variables
  end

  def analyze
    puts "🎨 Starting color analysis of ConsiderIt codebase..."
    puts "📁 Scanning directory: #{@root_path}"
    puts "🔍 Loaded #{@color_variables.length} color variables from color.coffee"
    
    Find.find(@root_path) do |path|
      next if File.directory?(path)
      next unless @file_extensions.include?(File.extname(path))
      next if skip_file?(path)
      
      analyze_file(path)
    end

    puts "✅ Analysis complete! Found #{@colors_found.length} unique colors."
    generate_reports
  end

  private

  def skip_file?(path)
    # Skip certain directories and files
    skip_patterns = [
      '/node_modules/',
      '/vendor/',
      '/tmp/',
      '/log/',
      '/lib/tasks/customizations/',
      '.min.js',
      '.min.css',
      '/public/build/',
      '/public/',
      'color_analysis.rb',
      "@client/dashboard/analytics.coffee",
      "state_graph.coffee",
      "@client/histogram-legacy.coffee",
      "@client/histogram_lab.coffee",
      "@client/banner_legacy.coffee"
    ]
    
    skip_patterns.any? { |pattern| path.include?(pattern) }
  end

  def analyze_file(file_path)
    begin
      content = File.read(file_path, encoding: 'UTF-8')
      extract_colors_from_content(content, file_path)
    rescue => e
      puts "⚠️  Error reading #{file_path}: #{e.message}"
    end
  end

  def extract_colors_from_content(content, file_path)
    line_number = 0
    in_ql_editor_block = false
    brace_depth = 0
    
    content.each_line do |line|
      line_number += 1
      
      begin
        # Skip lines that are defining the named_colors dictionary itself
        next if is_named_colors_definition_line?(line, file_path)
        
        # Track CSS blocks for .ql-editor rules (works in both CSS and CoffeeScript files)
        if is_css_file?(file_path) || file_path.end_with?('.coffee')
          # Check if we're entering a .ql-editor block
          if line.match(/\.ql-editor/)
            in_ql_editor_block = true
            brace_depth = 0
          end
          
          # Track braces to know when we exit the block
          if in_ql_editor_block
            brace_depth += line.count('{')
            brace_depth -= line.count('}')
            
            # If we've closed all braces, we're out of the .ql-editor block
            if brace_depth <= 0
              in_ql_editor_block = false
            end
          end
          
          # Skip color extraction if we're inside a .ql-editor block
          next if in_ql_editor_block
        end
        
        # Extract hex colors
        line.scan(COLOR_PATTERNS[:hex]) do |match|
          next if match.nil? || match.empty?
          hex_match = match.is_a?(Array) ? match.first : match
          hex_color = normalize_hex("##{hex_match}")
          if hex_color
            usage_pattern = detect_usage_pattern(line, "##{hex_match}")
            # Skip if this is a variable definition to avoid duplicate recording
            next if usage_pattern == :variable_definition
            record_color(hex_color, line.strip, file_path, line_number, 'hex', nil, nil, usage_pattern)
          end
        end
        
        # Extract RGB colors
        line.scan(COLOR_PATTERNS[:rgb]) do |r, g, b, a|
          next if r.nil? || g.nil? || b.nil?
          hex_color = rgb_to_hex(r.to_i, g.to_i, b.to_i)
          alpha = a ? ", alpha: #{a}" : ""
          original = "rgb#{a ? 'a' : ''}(#{r},#{g},#{b}#{a ? ",#{a}" : ''})"
          # For RGB detection, we need to check the specific RGB value in the line context
          usage_pattern = detect_usage_pattern(line, original)
          # Skip if this is a variable definition to avoid duplicate recording
          next if usage_pattern == :variable_definition
          record_color(hex_color, line.strip, file_path, line_number, 'rgb', original, alpha, usage_pattern)
        end
        
        # Extract HSL colors
        line.scan(COLOR_PATTERNS[:hsl]) do |h, s, l, a|
          next if h.nil? || s.nil? || l.nil?
          hex_color = hsl_to_hex(h.to_i, s.to_i, l.to_i)
          alpha = a ? ", alpha: #{a}" : ""
          original = "hsl#{a ? 'a' : ''}(#{h},#{s}%,#{l}%#{a ? ",#{a}" : ''})"
          usage_pattern = detect_usage_pattern(line, original)
          record_color(hex_color, line.strip, file_path, line_number, 'hsl', original, alpha, usage_pattern)
        end
        
        # Extract named colors
        line.scan(COLOR_PATTERNS[:named]) do |match|
          next if match.nil?
          # match is an array from scan, get the first (and only) element
          color_name = (match.is_a?(Array) ? match.first : match).to_s.downcase.strip
          next if color_name.empty?
          next unless NAMED_COLORS.key?(color_name)
          
          hex_color = NAMED_COLORS[color_name]
          usage_pattern = detect_usage_pattern(line, color_name)
          record_color(hex_color, line.strip, file_path, line_number, 'named', color_name, nil, usage_pattern)
        end
        
        # Extract variable definitions (window.var = "color")
        if match = line.match(USAGE_PATTERNS[:variable_definition])
          color_with_quotes = match[1] || match[2] || match[3]
          next if color_with_quotes.nil?
          color_value = color_with_quotes.gsub(/['"]/, '')
          hex_color = normalize_hex(color_value)
          if hex_color
            record_color(hex_color, line.strip, file_path, line_number, 'variable_definition', color_with_quotes, nil, :variable_definition)
          end
        end
        
        # Extract color variable references (prevent duplicates by prioritizing longer matches)
        already_recorded = Set.new
        
        # Sort variables by length (longest first) to prioritize specific matches like 'focus_color' over 'focus_color'
        sorted_variables = @color_variables.keys.sort_by { |k| -k.length }
        
        sorted_variables.each do |var_name|
          hex_color = @color_variables[var_name]
          if line.include?(var_name) && !already_recorded.include?("#{file_path}:#{line_number}")
            usage_pattern = detect_usage_pattern(line, var_name)
            # Skip if this is a variable definition to avoid duplicate recording
            next if usage_pattern == :variable_definition
            
            # For focus_color/focus_color, use the original color value if it exists to avoid duplicates
            if (var_name == 'focus_color' || var_name == 'focus_color' || var_name == 'focus_color') && @color_variables['focus_color_original']
              record_color(@color_variables['focus_color_original'], line.strip, file_path, line_number, 'variable', var_name, nil, usage_pattern)
            else
              record_color(hex_color, line.strip, file_path, line_number, 'variable', var_name, nil, usage_pattern)
            end
            
            # Mark this line as recorded to prevent duplicates
            already_recorded.add("#{file_path}:#{line_number}")
          end
        end
      rescue => e
        puts "⚠️  Error processing line #{line_number} in #{file_path}: #{e.message}"
        puts "    Line content: #{line.strip[0, 100]}"
      end
    end
  end

  def is_named_colors_definition_line?(line, file_path)
    # Check if this line is part of a named_colors dictionary definition
    # This includes both Ruby and CoffeeScript/JavaScript named color definitions
    
    # Ruby style: NAMED_COLORS = { ... } or within the hash definition
    return true if line.match(/NAMED_COLORS\s*=\s*\{/) || 
                   line.match(/^\s*['"][\w\s]+['"]\s*=>\s*['"]#[0-9a-fA-F]{6}['"]/) ||
                   (file_path.include?('color_analysis.rb') && line.match(/^\s*['"][\w\s]+['"]\s*=>\s*['"]#/))
    
    # CoffeeScript/JavaScript style: window.named_colors = { ... } or within the object
    return true if line.match(/named_colors\s*=/) ||
                   line.match(/^\s*['"][\w\s]+['"]\s*:\s*['"]#[0-9a-fA-F]{6}['"]/) ||
                   (file_path.end_with?('.coffee') && line.match(/^\s*['"][\w\s]+['"]\s*:\s*['"]#/))
    
    false
  end

  def is_css_file?(file_path)
    ['.css', '.scss', '.sass'].include?(File.extname(file_path))
  end

  def strip_css_comments(line)
    return '' if line.nil?
    
    # Remove CSS comments /* ... */ and CoffeeScript comments # ... to avoid interference with pattern matching
    cleaned = line.gsub(/\/\*.*?\*\//, '') # CSS comments
                 .gsub(/#\s+.*$/, '')      # CoffeeScript comments (# followed by space to end of line)
                 .strip
    cleaned
  end

  def detect_usage_pattern(line, color_value)
    # Strip comments before pattern detection
    clean_line = strip_css_comments(line)
    
    # First, check for variable definitions to prevent misclassification
    # Check for both direct hex assignments and variable-to-variable assignments
    if (clean_line.match(/window\.[\w_]+\s*=\s*['"]#[0-9a-fA-F]{3,8}['"]/) && clean_line.include?(color_value)) ||
       (clean_line.match(/window\.[\w_]+\s*=\s*\w+/) && clean_line.include?(color_value))
      return :variable_definition
    end
    
    # Create unified pattern checks that work for both direct colors and variable references
    line_lower = clean_line.downcase
    color_lower = color_value.downcase
    
    # Check for background patterns (most comprehensive)
    if line_lower.match(/(?:background-color|backgroundcolor|background)\s*[:=]\s*/) ||
       clean_line.match(/(?:background|background-color|backgroundColor)\s*:\s*.*#{Regexp.escape(color_value)}/i)
      return :background
    end
    
    # Check for text color patterns  
    if line_lower.match(/(?:^|[^-\w])color\s*[:=]\s*/) && !line_lower.include?('background') && !line_lower.include?('border') ||
       clean_line.match(/(?:^|[^-\w])color\s*:\s*.*#{Regexp.escape(color_value)}/i)
      return :text
    end
    
    # Check for border patterns (including border-top, border-right, border-*-color, etc.)
    if line_lower.match(/(?:border|border-color|border-top|border-right|border-bottom|border-left|border-top-color|border-right-color|border-bottom-color|border-left-color|bordercolor|bordertop|borderright|borderbottom|borderleft|bordertopcolor|borderrightcolor|borderbottomcolor|borderleftcolor)\s*[:=]\s*/) ||
       clean_line.match(/(?:border|border-color|border-top|border-right|border-bottom|border-left|border-top-color|border-right-color|border-bottom-color|border-left-color|borderColor|borderTop|borderRight|borderBottom|borderLeft|borderTopColor|borderRightColor|borderBottomColor|borderLeftColor)\s*:\s*.*#{Regexp.escape(color_value)}/i)
      return :border
    end
    
    # Check for shadow patterns
    if line_lower.match(/(?:box-shadow|boxshadow|text-shadow|textshadow|drop-shadow)\s*[:=]\s*/) ||
       clean_line.match(/(?:box-shadow|boxShadow|text-shadow|textShadow|drop-shadow)\s*:\s*.*#{Regexp.escape(color_value)}/i)
      return :shadow
    end
    
    # Check for icon patterns
    if clean_line.match(/(?:[\w_]*_?icon|Icon)\s+.*#{Regexp.escape(color_value)}/i) ||
       clean_line.match(/(?:[\w_]*_?icon|Icon)\s*\([^)]*#{Regexp.escape(color_value)}/i)
      return :icon
    end
    
    # Check for fill/stroke patterns
    if line_lower.match(/(?:fill|fillstyle)\s*[:=]\s*/) ||
       clean_line.match(/(?:fill|fillStyle)\s*[:=]\s*.*#{Regexp.escape(color_value)}/i)
      return :fill
    end
    
    if line_lower.match(/(?:stroke|strokestyle)\s*[:=]\s*/) ||
       clean_line.match(/(?:stroke|strokeStyle)\s*[:=]\s*.*#{Regexp.escape(color_value)}/i)
      return :stroke
    end
    
    # Check for outline patterns
    if line_lower.match(/(?:outline|outline-color|outlinecolor)\s*[:=]\s*/) ||
       clean_line.match(/(?:outline|outline-color|outlineColor)\s*:\s*.*#{Regexp.escape(color_value)}/i)
      return :outline
    end
    
    # Check for filter patterns
    if line_lower.match(/filter\s*[:=]\s*/) ||
       clean_line.match(/filter\s*:\s*.*#{Regexp.escape(color_value)}/i)
      return :filter
    end
    
    # Check for gradients
    if clean_line.match(/(?:linear-gradient|radial-gradient).*#{Regexp.escape(color_value)}/i)
      return :gradient
    end
    
    # Check for SVG elements
    if clean_line.match(/<(?:circle|rect|path|line|polygon|ellipse)[^>]*(?:fill|stroke)\s*=\s*['"]#{Regexp.escape(color_value)}/i)
      return :svg_element
    end
    
    # Special handling for CoffeeScript string interpolation
    interpolation_pattern = "#{" + color_value + "}"
    if clean_line.include?(interpolation_pattern)
      if clean_line.match(/(?:border|border-color|borderColor).*#\{.*#{Regexp.escape(color_value)}.*\}/i)
        return :border
      elsif clean_line.match(/(?:background|background-color|backgroundColor).*#\{.*#{Regexp.escape(color_value)}.*\}/i)
        return :background
      elsif clean_line.match(/(?:^|[^-\w])color\s*:.*#\{.*#{Regexp.escape(color_value)}.*\}/i)
        return :text
      elsif clean_line.match(/(?:box-shadow|boxShadow|text-shadow|textShadow).*#\{.*#{Regexp.escape(color_value)}.*\}/i)
        return :shadow
      elsif clean_line.match(/filter.*#\{.*#{Regexp.escape(color_value)}.*\}/i)
        return :filter
      end
    end
    
    # If no specific pattern found, return :other
    :other
  end

  def record_color(hex_color, line_content, file_path, line_number, type, original = nil, alpha = nil, usage_pattern = nil)
    # Skip if it's just a fragment of a larger hex number (like in URLs)
    return if hex_color.length > 9 # Skip malformed colors (allow up to 8-char hex+alpha)
    
    color_key = hex_color.downcase
    
    @colors_found[color_key] ||= {
      hex: hex_color,
      count: 0,
      locations: [],
      types: Set.new,
      originals: Set.new,
      usage_patterns: {
        background: [],
        text: [],
        border: [],
        shadow: [],
        fill: [],
        stroke: [],
        outline: [],
        icon: [],
        variable_definition: [],
        svg_element: [],
        gradient: [],
        function_parameter: [],
        config_property: [],
        opacity: [],
        transform: [],
        filter: [],
        other: []
      }
    }
    
    @colors_found[color_key][:count] += 1
    @colors_found[color_key][:types] << type
    @colors_found[color_key][:originals] << (original || hex_color)
    
    # Store all location info for HTML report
    relative_path = file_path.gsub(@root_path, '').gsub(/^\//, '')
    location_info = {
      file: relative_path,
      line: line_number,
      context: line_content.strip[0, 100] + (line_content.length > 100 ? '...' : ''),
      alpha: alpha
    }
    
    @colors_found[color_key][:locations] << location_info
    
    # Store usage pattern information
    pattern_key = usage_pattern || :other
    @colors_found[color_key][:usage_patterns][pattern_key] << location_info
  end

  def normalize_hex(hex)
    return nil if hex.nil? || hex.length < 4
    
    # Convert 3-digit hex to 6-digit
    if hex.length == 4 # #abc
      hex = "##{hex[1]}#{hex[1]}#{hex[2]}#{hex[2]}#{hex[3]}#{hex[3]}"
    end
    
    # Ensure it's a valid hex color (6 or 8 characters)
    valid_6 = hex.length == 7 && hex.match(/^#[0-9a-fA-F]{6}$/)
    valid_8 = hex.length == 9 && hex.match(/^#[0-9a-fA-F]{8}$/)
    return nil unless valid_6 || valid_8
    
    hex.upcase
  end

  def rgb_to_hex(r, g, b)
    "#%02X%02X%02X" % [r, g, b]
  end

  def hsl_to_hex(h, s, l)
    # Convert HSL to RGB, then to hex
    h = h / 360.0
    s = s / 100.0
    l = l / 100.0
    
    if s == 0
      r = g = b = l # achromatic
    else
      def hue_to_rgb(p, q, t)
        t += 1 if t < 0
        t -= 1 if t > 1
        return p + (q - p) * 6 * t if t < 1/6.0
        return q if t < 1/2.0
        return p + (q - p) * (2/3.0 - t) * 6 if t < 2/3.0
        return p
      end
      
      q = l < 0.5 ? l * (1 + s) : l + s - l * s
      p = 2 * l - q
      r = hue_to_rgb(p, q, h + 1/3.0)
      g = hue_to_rgb(p, q, h)
      b = hue_to_rgb(p, q, h - 1/3.0)
    end
    
    rgb_to_hex((r * 255).round, (g * 255).round, (b * 255).round)
  end

  def color_distance(hex1, hex2)
    # Simple RGB distance calculation
    r1, g1, b1 = hex_to_rgb(hex1)
    r2, g2, b2 = hex_to_rgb(hex2)
    
    Math.sqrt((r2-r1)**2 + (g2-g1)**2 + (b2-b1)**2)
  end

  def hex_to_rgb(hex)
    hex = hex.gsub('#', '')
    return [0, 0, 0] if hex.length != 6 && hex.length != 8
    
    [
      hex[0,2].to_i(16),
      hex[2,2].to_i(16),
      hex[4,2].to_i(16)
    ]
  end

  def is_gray?(hex)
    r, g, b = hex_to_rgb(hex)
    # A color is gray only if all RGB values are exactly equal (pure gray)
    r == g && g == b
  end

  def generate_reports
    puts "📊 Generating reports..."
    
    # Filter out transparent and invalid colors
    valid_colors = @colors_found.reject { |hex, _| hex == 'transparent' || (hex.length != 7 && hex.length != 9) }
    
    # Filter out ignored colors
    valid_colors = valid_colors.reject { |hex, _| IGNORED_COLORS.include?(hex.upcase) }
    
    # Filter out colors that appear only once and only in icons.coffee
    valid_colors = valid_colors.reject do |hex, data|
      data[:count] == 1 && data[:locations].length == 1 && 
      data[:locations].first[:file].include?('icons.coffee')
    end
    
    # Sort by frequency (most used first)
    by_frequency = valid_colors.sort_by { |_, data| -data[:count] }
    
    # Sort by hex similarity (group similar colors)
    by_similarity = group_by_similarity(valid_colors)
    
    # Generate frequency report
    generate_frequency_report(by_frequency)
    
    # Generate similarity report
    generate_similarity_report(by_similarity)
    
    # Generate interactive HTML report
    generate_html_report(by_similarity)
    
    # Generate usage patterns report
    generate_usage_patterns_report(valid_colors)
    
    # Generate consolidation suggestions
    generate_consolidation_report(by_similarity)
    
    # Generate JSON data for further analysis
    generate_json_report(valid_colors)
    
    puts "📁 Reports generated in color_analysis_output/ directory"
  end

  def group_by_similarity(colors)
    # Separate gray and non-gray colors
    gray_colors = colors.select { |hex, _| is_gray?(hex) }
    non_gray_colors = colors.reject { |hex, _| is_gray?(hex) }
    
    puts "📈 Found #{gray_colors.length} gray colors and #{non_gray_colors.length} non-gray colors"
    
    # Group all grays into a single group, sorted by brightness
    gray_groups = []
    if gray_colors.any?
      all_grays = gray_colors.map { |hex, data| { hex: hex, data: data } }
      gray_groups = [sort_colors_for_gradient(all_grays)]
    end
    
    # Group non-grays with regular similarity threshold
    non_gray_groups = group_colors_by_similarity(non_gray_colors, 50)
    
    # Return grays first, then non-grays
    gray_groups + non_gray_groups
  end

  def group_colors_by_similarity(colors, threshold)
    grouped = []
    processed = Set.new
    
    colors.each do |hex, data|
      next if processed.include?(hex)
      
      group = [{ hex: hex, data: data }]
      processed << hex
      
      # Find similar colors (within distance threshold)
      colors.each do |other_hex, other_data|
        next if processed.include?(other_hex)
        
        distance = color_distance(hex, other_hex)
        if distance < threshold
          group << { hex: other_hex, data: other_data }
          processed << other_hex
        end
      end
      
      # Sort group to create gradient effect
      group = sort_colors_for_gradient(group)
      grouped << group
    end
    
    # Separate single-color groups from multi-color groups
    multi_color_groups = grouped.select { |group| group.length > 1 }
    single_color_groups = grouped.select { |group| group.length == 1 }
    
    # Sort multi-color groups by total usage count
    multi_color_groups.sort_by! { |group| -group.sum { |item| item[:data][:count] } }
    
    # Create miscellaneous group from all single-color groups
    misc_group = single_color_groups.flatten
    misc_group = sort_colors_for_gradient(misc_group) if misc_group.any?
    
    # Return multi-color groups first, then miscellaneous group (if any)
    result = multi_color_groups
    result << misc_group if misc_group.any?
    result
  end

  def sort_colors_for_gradient(group)
    return group if group.length <= 1
    
    # Check if this is a gray group (all colors are gray)
    all_gray = group.all? { |item| is_gray?(item[:hex]) }
    
    if all_gray
      # For grays, sort by brightness and alpha (dark to light, transparent to opaque)
      group.sort_by { |item| get_gray_sort_key(item[:hex]) }
    else
      # For colored groups, sort by hue to create rainbow-like gradients
      group.sort_by { |item| get_hue(item[:hex]) }
    end
  end

  def get_brightness(hex)
    r, g, b = hex_to_rgb(hex)
    # Calculate relative luminance
    (r * 299 + g * 587 + b * 114) / 1000.0
  end

  def get_gray_sort_key(hex)
    # For gray colors, create a sort key that considers both brightness and alpha
    brightness = get_brightness(hex)
    alpha = get_alpha_value(hex)
    
    # Primary sort by brightness (dark to light)
    # Secondary sort by alpha (transparent to opaque) - multiply by small factor to make it secondary
    brightness + (alpha / 255.0) * 0.001
  end

  def get_alpha_value(hex)
    hex_clean = hex.gsub('#', '')
    if hex_clean.length == 8
      # Extract alpha from 8-character hex
      hex_clean[6, 2].to_i(16)
    else
      # No alpha channel, assume fully opaque
      255
    end
  end

  def get_hue(hex)
    r, g, b = hex_to_rgb(hex)
    
    # Convert RGB to HSL to get hue
    r = r / 255.0
    g = g / 255.0
    b = b / 255.0
    
    max = [r, g, b].max
    min = [r, g, b].min
    delta = max - min
    
    return 0 if delta == 0 # Achromatic (gray)
    
    hue = case max
          when r
            60 * (((g - b) / delta) % 6)
          when g
            60 * (((b - r) / delta) + 2)
          when b
            60 * (((r - g) / delta) + 4)
          end
    
    hue < 0 ? hue + 360 : hue
  end

  def generate_frequency_report(colors)
    Dir.mkdir('color_analysis_output') unless Dir.exist?('color_analysis_output')
    
    File.open('color_analysis_output/colors_by_frequency.csv', 'w') do |file|
      file.puts "Rank,Hex,Count,Types,Original_Forms,Sample_Files"
      
      colors.each_with_index do |(hex, data), index|
        types = data[:types].to_a.join(';')
        originals = data[:originals].to_a.join(';')
        sample_files = data[:locations][0,3].map { |loc| "#{loc[:file]}:#{loc[:line]}" }.join(';')
        
        file.puts "#{index + 1},#{hex},#{data[:count]},\"#{types}\",\"#{originals}\",\"#{sample_files}\""
      end
    end
    
    puts "✅ Frequency report: color_analysis_output/colors_by_frequency.csv"
  end

  def generate_similarity_report(grouped_colors)
    File.open('color_analysis_output/colors_by_similarity.txt', 'w') do |file|
      file.puts "🎨 ConsiderIt Color Analysis - Grouped by Similarity"
      file.puts "=" * 60
      file.puts
      
      gray_groups = []
      non_gray_groups = []
      
      # Separate groups into gray and non-gray
      grouped_colors.each do |group|
        first_color = group.first[:hex]
        if is_gray?(first_color)
          gray_groups << group
        else
          non_gray_groups << group
        end
      end
      
      # Gray colors section
      if gray_groups.any?
        file.puts "🔘 GRAY COLORS"
        file.puts "=" * 30
        file.puts "Found #{gray_groups.length} groups of gray colors"
        file.puts
        
        gray_groups.each_with_index do |group, group_index|
          total_count = group.sum { |item| item[:data][:count] }
          file.puts "GRAY GROUP #{group_index + 1} (Total usage: #{total_count})"
          file.puts "-" * 40
          
          group.each do |item|
            hex = item[:hex]
            data = item[:data]
            file.puts "  #{hex} (used #{data[:count]} times)"
            file.puts "    Types: #{data[:types].to_a.join(', ')}"
            file.puts "    Forms: #{data[:originals].to_a[0,3].join(', ')}"
            
            if data[:locations].any?
              file.puts "    Examples:"
              data[:locations][0,2].each do |loc|
                file.puts "      #{loc[:file]}:#{loc[:line]} - #{loc[:context]}"
              end
            end
            file.puts
          end
          
          file.puts
        end
      end
      
      # Non-gray colors section
      if non_gray_groups.any?
        file.puts "🌈 NON-GRAY COLORS"
        file.puts "=" * 30
        file.puts "Found #{non_gray_groups.length} groups of colored elements"
        file.puts
        
        non_gray_groups.each_with_index do |group, group_index|
          total_count = group.sum { |item| item[:data][:count] }
          
          # Check if this is the last group and has many different colors (likely miscellaneous)
          is_misc_group = group_index == non_gray_groups.length - 1 && group.length > 3
          group_title = if is_misc_group
            "MISCELLANEOUS COLORS (Total usage: #{total_count})"
          else
            "COLOR GROUP #{group_index + 1} (Total usage: #{total_count})"
          end
          
          file.puts group_title
          file.puts "-" * 40
          
          group.each do |item|
            hex = item[:hex]
            data = item[:data]
            file.puts "  #{hex} (used #{data[:count]} times)"
            file.puts "    Types: #{data[:types].to_a.join(', ')}"
            file.puts "    Forms: #{data[:originals].to_a[0,3].join(', ')}"
            
            if data[:locations].any?
              file.puts "    Examples:"
              data[:locations][0,2].each do |loc|
                file.puts "      #{loc[:file]}:#{loc[:line]} - #{loc[:context]}"
              end
            end
            file.puts
          end
          
          file.puts
        end
      end
    end
    
    puts "✅ Similarity report: color_analysis_output/colors_by_similarity.txt"
  end

  def generate_html_report(grouped_colors)
    File.open('color_analysis_output/colors_by_similarity.html', 'w') do |file|
      file.puts generate_html_content(grouped_colors)
    end
    
    puts "✅ HTML interactive report: color_analysis_output/colors_by_similarity.html"
  end

  def generate_html_content(grouped_colors)
    gray_groups_no_alpha = []
    gray_groups_with_alpha = []
    non_gray_groups_no_alpha = []
    non_gray_groups_with_alpha = []
    
    # Separate groups into 4 categories: gray/non-gray × alpha/no-alpha
    grouped_colors.each do |group|
      # Categorize the group based on its first color
      first_color = group.first[:hex]
      is_gray = is_gray?(first_color)
      has_alpha = has_alpha_channel?(first_color)
      
      if is_gray && has_alpha
        gray_groups_with_alpha << group
      elsif is_gray && !has_alpha
        gray_groups_no_alpha << group
      elsif !is_gray && has_alpha
        non_gray_groups_with_alpha << group
      else # !is_gray && !has_alpha
        non_gray_groups_no_alpha << group
      end
    end

    html = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>ConsiderIt Color Analysis - Interactive Report</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f8f9fa;
            color: #333;
          }
          .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 30px;
          }
          h1 {
            color: #2c3e50;
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
          }
          h2 {
            color: #34495e;
            margin-top: 40px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
          }
          .group {
            margin-bottom: 30px;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            overflow: hidden;
          }
          .group-header {
            background: #f1f3f4;
            padding: 15px 20px;
            font-weight: 600;
            color: #444;
            border-bottom: 1px solid #e0e0e0;
          }
          .color-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(80px, 1fr));
            gap: 1px;
            padding: 1px;
          }
          .color-square {
            aspect-ratio: 1;
            cursor: pointer;
            transition: all 0.2s ease;
            position: relative;
            min-height: 80px;
            display: flex;
            align-items: flex-end;
            justify-content: center;
            padding: 5px;
            box-sizing: border-box;
          }
          .color-square:hover {
            transform: scale(1.05);
            z-index: 10;
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
          }
          .color-label {
            background: rgba(255,255,255,0.9);
            color: #333;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 10px;
            font-weight: 600;
            text-shadow: none;
          }
          .color-square.dark .color-label {
            background: rgba(0,0,0,0.8);
            color: white;
          }
          .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
          }
          .modal-content {
            background-color: white;
            margin: 5% auto;
            padding: 30px;
            border-radius: 8px;
            width: 80%;
            max-width: 800px;
            max-height: 80vh;
            overflow-y: auto;
            position: relative;
          }
          .close {
            color: #aaa;
            float: right;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
            position: absolute;
            right: 20px;
            top: 15px;
          }
          .close:hover {
            color: #000;
          }
          .color-info {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
            align-items: center;
          }
          .color-preview {
            width: 100px;
            height: 100px;
            border-radius: 8px;
            border: 2px solid #ddd;
            flex-shrink: 0;
          }
          .color-details h3 {
            margin: 0 0 10px 0;
            color: #2c3e50;
          }
          .color-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
          }
          .stat-box {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            border-left: 4px solid #3498db;
          }
          .stat-label {
            font-weight: 600;
            color: #666;
            font-size: 12px;
            text-transform: uppercase;
            margin-bottom: 5px;
          }
          .stat-value {
            font-size: 18px;
            color: #2c3e50;
            font-weight: 600;
          }
          .usage-list {
            background: #f8f9fa;
            border-radius: 6px;
            padding: 15px;
            max-height: 300px;
            overflow-y: auto;
          }
          .usage-item {
            padding: 8px 0;
            border-bottom: 1px solid #e0e0e0;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 12px;
          }
          .usage-item:last-child {
            border-bottom: none;
          }
          .usage-file {
            color: #3498db;
            font-weight: 600;
          }
          .file-link {
            color: #3498db;
            text-decoration: none;
            cursor: pointer;
          }
          .file-link:hover {
            color: #2980b9;
            text-decoration: underline;
          }
          .usage-context {
            color: #666;
            margin-top: 3px;
            background: white;
            padding: 5px;
            border-radius: 3px;
            word-break: break-all;
          }
          .summary {
            background: #e8f5e8;
            border: 1px solid #4caf50;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 20px;
          }
          .emoji {
            font-size: 1.2em;
          }
          .filter-section {
            background: #f8f9fa;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 20px;
          }
          .filter-input {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
          }
          .filter-help {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🎨 ConsiderIt Color Analysis - Interactive Report</h1>
          
          <div class="summary">
            <strong>Analysis Summary:</strong>
            #{grouped_colors.flatten.length} unique colors found across the codebase.
            Colors are grouped by similarity and separated into grays/non-grays, with/without alpha channels.
            Click any color square to see detailed usage information.
          </div>
          
          <div class="filter-section">
            <label for="fileFilter"><strong>🔍 Filter by File:</strong></label>
            <input type="text" id="fileFilter" class="filter-input" placeholder="Enter file path or pattern (e.g., banner.coffee, @client/, .css)">
            <div class="filter-help">Filter to show only colors used in files matching the pattern. Leave empty to show all colors.</div>
            
            <br><br>
            <label><strong>🎯 Variable Filter:</strong></label>
            <button id="variableFilterToggle" class="filter-button" onclick="toggleVariableFilter()" style="margin-left: 10px; padding: 8px 16px; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer;">
              Hide Variable Uses
            </button>
            <div class="filter-help">Click to hide/show colors that are already using variables (helps identify hardcoded colors that need replacement).</div>
          </div>
    HTML

    # Gray colors (no alpha) section
    if gray_groups_no_alpha.any?
      html += <<~HTML
        <h2><span class="emoji">🔘</span> Gray Colors (#{gray_groups_no_alpha.length} groups)</h2>
      HTML
      
      gray_groups_no_alpha.each_with_index do |group, group_index|
        total_count = group.sum { |item| item[:data][:count] }
        html += <<~HTML
          <div class="group">
            <div class="group-header">
              Gray Group #{group_index + 1} - #{group.length} colors, #{total_count} total uses
            </div>
            <div class="color-grid">
        HTML
        
        group.each do |item|
          hex = item[:hex]
          data = item[:data]
          is_dark = is_color_dark?(hex)
          
          files_used = data[:locations].map { |loc| loc[:file] }.uniq.join(';')
          html += <<~HTML
            <div class="color-square #{is_dark ? 'dark' : ''}" 
                 style="background-color: #{hex}" 
                 data-files="#{files_used}"
                 onclick="showColorDetails('#{hex.gsub('#', '')}')">
              <div class="color-label">#{data[:count]}</div>
            </div>
          HTML
        end
        
        html += "</div></div>"
      end
    end

    # Gray colors with alpha section
    if gray_groups_with_alpha.any?
      html += <<~HTML
        <h2><span class="emoji">🔘🟨</span> Gray Colors with Alpha (#{gray_groups_with_alpha.length} groups)</h2>
      HTML
      
      gray_groups_with_alpha.each_with_index do |group, group_index|
        total_count = group.sum { |item| item[:data][:count] }
        html += <<~HTML
          <div class="group">
            <div class="group-header">
              Gray Alpha Group #{group_index + 1} - #{group.length} colors, #{total_count} total uses
            </div>
            <div class="color-grid">
        HTML
        
        group.each do |item|
          hex = item[:hex]
          data = item[:data]
          is_dark = is_color_dark?(hex)
          
          files_used = data[:locations].map { |loc| loc[:file] }.uniq.join(';')
          html += <<~HTML
            <div class="color-square #{is_dark ? 'dark' : ''}" 
                 style="background-color: #{hex}" 
                 data-files="#{files_used}"
                 onclick="showColorDetails('#{hex.gsub('#', '')}')">
              <div class="color-label">#{data[:count]}</div>
            </div>
          HTML
        end
        
        html += "</div></div>"
      end
    end

    # Non-gray colors (no alpha) section  
    if non_gray_groups_no_alpha.any?
      html += <<~HTML
        <h2><span class="emoji">🌈</span> Non-Gray Colors (#{non_gray_groups_no_alpha.length} groups)</h2>
      HTML
      
      non_gray_groups_no_alpha.each_with_index do |group, group_index|
        total_count = group.sum { |item| item[:data][:count] }
        
        # Check if this is the last group and has many different colors (likely miscellaneous)
        is_misc_group = group_index == non_gray_groups_no_alpha.length - 1 && group.length > 3
        group_title = if is_misc_group
          "Miscellaneous Colors - #{group.length} colors, #{total_count} total uses"
        else
          "Color Group #{group_index + 1} - #{group.length} colors, #{total_count} total uses"
        end
        
        html += <<~HTML
          <div class="group">
            <div class="group-header">
              #{group_title}
            </div>
            <div class="color-grid">
        HTML
        
        group.each do |item|
          hex = item[:hex]
          data = item[:data]
          is_dark = is_color_dark?(hex)
          
          files_used = data[:locations].map { |loc| loc[:file] }.uniq.join(';')
          html += <<~HTML
            <div class="color-square #{is_dark ? 'dark' : ''}" 
                 style="background-color: #{hex}" 
                 data-files="#{files_used}"
                 onclick="showColorDetails('#{hex.gsub('#', '')}')">
              <div class="color-label">#{data[:count]}</div>
            </div>
          HTML
        end
        
        html += "</div></div>"
      end
    end

    # Non-gray colors with alpha section  
    if non_gray_groups_with_alpha.any?
      html += <<~HTML
        <h2><span class="emoji">🌈🟨</span> Non-Gray Colors with Alpha (#{non_gray_groups_with_alpha.length} groups)</h2>
      HTML
      
      non_gray_groups_with_alpha.each_with_index do |group, group_index|
        total_count = group.sum { |item| item[:data][:count] }
        
        # Check if this is the last group and has many different colors (likely miscellaneous)
        is_misc_group = group_index == non_gray_groups_with_alpha.length - 1 && group.length > 3
        group_title = if is_misc_group
          "Miscellaneous Alpha Colors - #{group.length} colors, #{total_count} total uses"
        else
          "Alpha Color Group #{group_index + 1} - #{group.length} colors, #{total_count} total uses"
        end
        
        html += <<~HTML
          <div class="group">
            <div class="group-header">
              #{group_title}
            </div>
            <div class="color-grid">
        HTML
        
        group.each do |item|
          hex = item[:hex]
          data = item[:data]
          is_dark = is_color_dark?(hex)
          
          files_used = data[:locations].map { |loc| loc[:file] }.uniq.join(';')
          html += <<~HTML
            <div class="color-square #{is_dark ? 'dark' : ''}" 
                 style="background-color: #{hex}" 
                 data-files="#{files_used}"
                 onclick="showColorDetails('#{hex.gsub('#', '')}')">
              <div class="color-label">#{data[:count]}</div>
            </div>
          HTML
        end
        
        html += "</div></div>"
      end
    end

    # Modal and JavaScript
    html += <<~HTML
        </div>

        <!-- Modal -->
        <div id="colorModal" class="modal">
          <div class="modal-content">
            <span class="close" onclick="closeModal()">&times;</span>
            <div id="modalContent"></div>
          </div>
        </div>

        <script>
          const colorData = #{generate_color_data_json(grouped_colors)};

          function showColorDetails(hexWithoutHash) {
            const hex = '#' + hexWithoutHash.toUpperCase();
            const colorInfo = findColorData(hex);
            
            if (!colorInfo) {
              console.error('Color not found:', hex);
              return;
            }

            // Get current file filter
            const filterValue = document.getElementById('fileFilter').value.toLowerCase().trim();
            
            // Filter locations based on current file filter
            const filteredLocations = filterValue ? 
              colorInfo.locations.filter(loc => loc.file.toLowerCase().includes(filterValue)) :
              colorInfo.locations;

            const modalContent = document.getElementById('modalContent');
            const isDark = isColorDark(hex);
            const titleSuffix = filterValue ? ` (filtered by "${filterValue}")` : '';
            
            modalContent.innerHTML = `
              <div class="color-info">
                <div class="color-preview" style="background-color: ${hex}; border-color: ${isDark ? '#fff' : '#000'}"></div>
                <div class="color-details">
                  <h3>${hex}</h3>
                  <p><strong>Usage${titleSuffix}:</strong> ${filteredLocations.length} time${filteredLocations.length === 1 ? '' : 's'} across ${filteredLocations.length} location${filteredLocations.length === 1 ? '' : 's'}</p>
                  ${filterValue ? `<p style="color: #e74c3c; font-size: 14px; font-style: italic;">Showing only uses in files matching "${filterValue}"</p>` : ''}
                </div>
              </div>
              
              <div class="color-stats">
                <div class="stat-box">
                  <div class="stat-label">Total Uses${filterValue ? ' (Filtered)' : ''}</div>
                  <div class="stat-value">${filteredLocations.length}</div>
                </div>
                <div class="stat-box">
                  <div class="stat-label">Locations${filterValue ? ' (Filtered)' : ''}</div>
                  <div class="stat-value">${filteredLocations.length}</div>
                </div>
                <div class="stat-box">
                  <div class="stat-label">Types</div>
                  <div class="stat-value">${colorInfo.types.join(', ')}</div>
                </div>
                <div class="stat-box">
                  <div class="stat-label">Forms Used</div>
                  <div class="stat-value">${colorInfo.originals.length}</div>
                </div>
              </div>

              <h4>Original Forms:</h4>
              <div style="background: #f8f9fa; padding: 10px; border-radius: 4px; margin-bottom: 15px; font-family: monospace;">
                ${colorInfo.originals.join(', ')}
              </div>
              
              <h4>All Usages${titleSuffix} (${filteredLocations.length} location${filteredLocations.length === 1 ? '' : 's'}):</h4>
              <div class="usage-list">
                ${filteredLocations.length > 0 ?
                  filteredLocations.map(loc => `
                    <div class="usage-item">
                      <div class="usage-file">
                        <a href="#" 
                           class="file-link" 
                           onclick="openInSublime('#{@root_path}/${loc.file}', ${loc.line}); return false;"
                           title="Click to open in Sublime Text">
                          ${loc.file}:${loc.line}
                        </a>
                      </div>
                      <div class="usage-context">${escapeHtml(loc.context)}</div>
                    </div>
                  `).join('') :
                  '<div class="usage-item" style="text-align: center; color: #999; font-style: italic;">No uses found in the filtered files.</div>'
                }
              </div>
            `;
            
            document.getElementById('colorModal').style.display = 'block';
          }

          function findColorData(hex) {
            return colorData[hex.toLowerCase()];
          }

          function isColorDark(hex) {
            const r = parseInt(hex.substr(1,2), 16);
            const g = parseInt(hex.substr(3,2), 16);
            const b = parseInt(hex.substr(5,2), 16);
            const brightness = (r * 299 + g * 587 + b * 114) / 1000;
            return brightness < 128;
          }

          function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
          }

          function openInSublime(filePath, lineNumber) {
            // Try to make a request to a local HTTP server that will open the file
            fetch(`http://localhost:9999/open?file=${encodeURIComponent(filePath)}&line=${lineNumber}`)
              .catch(() => {
                // Fallback: try to use subl:// URL scheme
                const sublUrl = `subl://open?url=file://${encodeURIComponent(filePath)}&line=${lineNumber}`;
                window.location.href = sublUrl;
              });
          }

          function closeModal() {
            document.getElementById('colorModal').style.display = 'none';
          }

          function filterByFile() {
            const filterValue = document.getElementById('fileFilter').value.toLowerCase().trim();
            const colorSquares = document.querySelectorAll('.color-square');
            
            colorSquares.forEach(square => {
              const colorHex = square.getAttribute('onclick').match(/'([^']+)'/)[1];
              const fullHex = '#' + colorHex;
              const colorInfo = colorData[fullHex.toLowerCase()];
              
              if (!filterValue) {
                // Show all if no filter - restore original counts
                square.style.display = '';
                const label = square.querySelector('.color-label');
                if (label && colorInfo) {
                  label.textContent = colorInfo.count;
                }
                return;
              }
              
              // Calculate filtered usage count
              let filteredCount = 0;
              if (colorInfo && colorInfo.locations) {
                filteredCount = colorInfo.locations.filter(loc => 
                  loc.file.toLowerCase().includes(filterValue)
                ).length;
              }
              
              if (filteredCount > 0) {
                // Show color and update count
                square.style.display = '';
                const label = square.querySelector('.color-label');
                if (label) {
                  label.textContent = filteredCount;
                }
              } else {
                // Hide color completely
                square.style.display = 'none';
              }
            });
            
            // Update group headers to show filtered counts
            updateGroupHeaders(filterValue);
          }
          
          function updateGroupHeaders(filterValue) {
            const groups = document.querySelectorAll('.group');
            
            groups.forEach(group => {
              const squares = group.querySelectorAll('.color-square');
              const visibleSquares = Array.from(squares).filter(square => 
                square.style.display !== 'none'
              );
              
              const header = group.querySelector('.group-header');
              if (header && header.textContent) {
                const originalText = header.getAttribute('data-original-text') || header.textContent;
                header.setAttribute('data-original-text', originalText);
                
                if (!filterValue) {
                  header.textContent = originalText;
                } else {
                  // Calculate total filtered uses for this group
                  let totalFilteredUses = 0;
                  visibleSquares.forEach(square => {
                    const label = square.querySelector('.color-label');
                    if (label) {
                      totalFilteredUses += parseInt(label.textContent) || 0;
                    }
                  });
                  
                  const groupMatch = originalText.match(/^(.+?) - (\d+) colors?, (\d+) total uses?$/);
                  if (groupMatch) {
                    const groupName = groupMatch[1];
                    header.textContent = `${groupName} - ${visibleSquares.length} colors, ${totalFilteredUses} total uses (filtered)`;
                  }
                }
              }
              
              // Hide group if no visible colors
              if (visibleSquares.length === 0) {
                group.style.display = 'none';
              } else {
                group.style.display = '';
              }
            });
          }

          // Add event listener for real-time filtering
          document.addEventListener('DOMContentLoaded', function() {
            const filterInput = document.getElementById('fileFilter');
            if (filterInput) {
              filterInput.addEventListener('input', filterByFile);
            }
          });

          let variableFilterActive = false;
          // Store original counts
          let originalCounts = {};

          function toggleVariableFilter() {
            variableFilterActive = !variableFilterActive;
            const button = document.getElementById('variableFilterToggle');
            
            if (variableFilterActive) {
              // Store original counts before filtering
              document.querySelectorAll('.tab').forEach(tab => {
                const onclick = tab.getAttribute('onclick');
                if (onclick) {
                  const tabMatch = onclick.match(/showTab\\('([^']+)'/);
                  if (tabMatch) {
                    const tabName = tabMatch[1];
                    const countElement = tab.querySelector('.pattern-count');
                    if (countElement) {
                      originalCounts[tabName] = countElement.textContent;
                    }
                  }
                }
              });
              
              button.textContent = 'Show Variable Uses';
              button.style.background = '#e74c3c';
            } else {
              // Restore original counts
              document.querySelectorAll('.tab').forEach(tab => {
                const onclick = tab.getAttribute('onclick');
                if (onclick) {
                  const tabMatch = onclick.match(/showTab\\('([^']+)'/);
                  if (tabMatch) {
                    const tabName = tabMatch[1];
                    const countElement = tab.querySelector('.pattern-count');
                    if (countElement && originalCounts[tabName]) {
                      countElement.textContent = originalCounts[tabName];
                    }
                  }
                }
              });
              
              button.textContent = 'Hide Variable Uses';
              button.style.background = '#3498db';
            }
            
            applyVariableFilter();
          }

          function applyVariableFilter() {
            const colorSquares = document.querySelectorAll('.color-square');
            
            colorSquares.forEach(square => {
              if (!variableFilterActive) {
                square.style.display = 'block';
                return;
              }
              
              // Get the color hex from the onclick attribute
              const onclick = square.getAttribute('onclick');
              if (!onclick) return;
              
              const match = onclick.match(/showColorDetails\\('([^']+)'/);
              if (!match) return;
              
              const colorHex = '#' + match[1];
              
              // Check if this color has variable usage by looking at the data
              const colorInfo = colorData[colorHex.toLowerCase()];
              if (!colorInfo) {
                square.style.display = 'block';
                return;
              }
              
              // Check if any usage contains variable references
              const hasVariableUsage = colorInfo.locations.some(location => {
                const context = location.context.toLowerCase();
                // Look for common variable patterns: variables or interpolation
                return context.includes('bg_') || context.includes('text_') || context.includes('brd_') || 
                       context.includes('shadow_') || context.includes('focus_') || context.includes('selected_') ||
                       context.includes('slidergram_') || context.includes('logo_') || context.includes('attention_') ||
                       context.includes('failure_') || context.includes('success_') || context.includes('caution_') ||
                       context.includes('upgrade_') || context.includes('considerit_') ||
                       context.includes('#' + '{');
              });
              
              if (hasVariableUsage) {
                square.style.display = 'none';
              } else {
                square.style.display = 'block';
              }
            });
            
            // Update group counts in similarity view
            updateGroupCounts();
          }

          function updateGroupCounts() {
            document.querySelectorAll('.group').forEach(group => {
              const visibleSquares = group.querySelectorAll('.color-square[style*="display: block"], .color-square:not([style*="display: none"])');
              const header = group.querySelector('.group-header');
              if (header) {
                // Store original text if not already stored
                if (!header.getAttribute('data-original-text')) {
                  header.setAttribute('data-original-text', header.textContent);
                }
                
                const originalText = header.getAttribute('data-original-text');
                const baseText = originalText.replace(/ - \d+ colors?, \d+ total uses.*$/, '');
                
                if (variableFilterActive) {
                  // Calculate total filtered uses
                  let totalUses = 0;
                  visibleSquares.forEach(square => {
                    const colorHex = square.getAttribute('onclick').match(/showColorDetails\('([^']+)'/)[1];
                    const fullHex = '#' + colorHex;
                    const colorInfo = colorData[fullHex.toLowerCase()];
                    if (colorInfo) {
                      totalUses += colorInfo.count;
                    }
                  });
                  
                  header.textContent = baseText + ' - ' + visibleSquares.length + ' colors, ' + totalUses + ' total uses (filtered)';
                } else {
                  header.textContent = originalText;
                }
              }
            });
          }

          window.onclick = function(event) {
            const modal = document.getElementById('colorModal');
            if (event.target === modal) {
              closeModal();
            }
          }
        </script>
      </body>
      </html>
    HTML

    html
  end

  def is_color_dark?(hex)
    r, g, b = hex_to_rgb(hex)
    brightness = (r * 299 + g * 587 + b * 114) / 1000
    brightness < 128
  end

  def generate_color_data_json(grouped_colors)
    data = {}
    
    grouped_colors.each do |group|
      group.each do |item|
        hex = item[:hex]
        color_data = item[:data]
        
        data[hex.downcase] = {
          hex: hex,
          count: color_data[:count],
          types: color_data[:types].to_a,
          originals: color_data[:originals].to_a,
          locations: color_data[:locations]
        }
      end
    end
    
    JSON.generate(data)
  end

  def generate_consolidation_report(grouped_colors)
    File.open('color_analysis_output/consolidation_suggestions.md', 'w') do |file|
      file.puts "# 🎨 Color Consolidation Suggestions for ConsiderIt"
      file.puts
      file.puts "This report identifies groups of similar colors that could be consolidated into a single color value."
      file.puts
      
      consolidation_groups = grouped_colors.select { |group| group.length > 1 }
      
      file.puts "## Summary"
      file.puts "- **Total unique colors found**: #{@colors_found.length}"
      file.puts "- **Groups with similar colors**: #{consolidation_groups.length}"
      file.puts "- **Potential color reduction**: #{consolidation_groups.sum { |g| g.length - 1 }} colors"
      file.puts
      
      file.puts "## Consolidation Opportunities"
      file.puts
      
      consolidation_groups.each_with_index do |group, index|
        total_usage = group.sum { |item| item[:data][:count] }
        primary_color = group.first[:hex]
        
        file.puts "### Group #{index + 1}: #{group.length} similar colors (#{total_usage} total uses)"
        file.puts
        file.puts "**Suggested primary color**: `#{primary_color}` (most used: #{group.first[:data][:count]} times)"
        file.puts
        file.puts "**Colors to consolidate**:"
        group.each do |item|
          percentage = (item[:data][:count].to_f / total_usage * 100).round(1)
          file.puts "- `#{item[:hex]}` - #{item[:data][:count]} uses (#{percentage}%)"
        end
        file.puts
        
        file.puts "**Benefits of consolidation**:"
        file.puts "- Reduces color palette by #{group.length - 1} colors"
        file.puts "- Improves visual consistency"
        file.puts "- Easier maintenance and theming"
        file.puts
        file.puts "---"
        file.puts
      end
    end
    
    puts "✅ Consolidation report: color_analysis_output/consolidation_suggestions.md"
  end

  def generate_json_report(colors)
    File.open('color_analysis_output/color_data.json', 'w') do |file|
      file.puts JSON.pretty_generate({
        analysis_date: Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
        total_colors: colors.length,
        colors: colors
      })
    end
    
    puts "✅ JSON data: color_analysis_output/color_data.json"
  end

  def generate_usage_patterns_report(colors)
    File.open('color_analysis_output/colors_by_usage.html', 'w') do |file|
      file.puts generate_usage_patterns_html(colors)
    end
    
    puts "✅ Usage patterns report: color_analysis_output/colors_by_usage.html"
  end

  def generate_usage_patterns_html(colors)
    # Group colors by usage pattern
    usage_groups = {
      background: {},
      text: {},
      border: {},
      shadow: {},
      fill: {},
      stroke: {},
      outline: {},
      icon: {},
      variable_definition: {},
      svg_element: {},
      gradient: {},
      function_parameter: {},
      config_property: {},
      custom_property: {},
      opacity: {},
      transform: {},
      filter: {},
      other: {}
    }

    colors.each do |hex, data|
      data[:usage_patterns].each do |pattern, locations|
        next if locations.empty?
        usage_groups[pattern][hex] = {
          hex: hex,
          data: data,
          usage_count: locations.length,
          locations: locations
        }
      end
    end

    # Generate HTML
    html = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>ConsiderIt Colors by Usage Pattern - Interactive Report</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f8f9fa;
            color: #333;
            line-height: 1.6;
          }
          .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 30px;
          }
          h1 {
            color: #2c3e50;
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
          }
          .summary {
            background: #e8f5e8;
            border: 1px solid #4caf50;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 30px;
          }
          .tabs {
            display: flex;
            border-bottom: 2px solid #e0e0e0;
            margin-bottom: 20px;
            flex-wrap: wrap;
          }
          .tab {
            padding: 10px 20px;
            cursor: pointer;
            border: none;
            background: none;
            font-size: 14px;
            font-weight: 600;
            color: #666;
            border-radius: 6px 6px 0 0;
            margin-right: 5px;
            transition: all 0.2s ease;
          }
          .tab.active {
            background: #3498db;
            color: white;
          }
          .tab:hover:not(.active) {
            background: #f1f3f4;
            color: #333;
          }
          .tab-content {
            display: none;
          }
          .tab-content.active {
            display: block;
          }
          .usage-section {
            margin-bottom: 30px;
          }
          .usage-header {
            background: #f1f3f4;
            padding: 15px 20px;
            font-weight: 600;
            color: #444;
            border-radius: 6px 6px 0 0;
            border-bottom: 1px solid #e0e0e0;
            margin-bottom: 0;
          }
          .color-group {
            margin-bottom: 30px;
          }
          .group-header {
            background: #f8f9fa;
            border: 1px solid #e0e0e0;
            border-radius: 6px 6px 0 0;
            padding: 12px 20px;
            margin: 0 0 0 0;
            font-size: 16px;
            font-weight: 600;
            color: #495057;
            border-bottom: 1px solid #e0e0e0;
          }
          .color-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
            gap: 15px;
            padding: 20px;
            background: white;
            border: 1px solid #e0e0e0;
            border-top: none;
            border-radius: 0 0 6px 6px;
          }
          .color-card {
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            overflow: hidden;
            cursor: pointer;
            transition: all 0.2s ease;
            background: white;
          }
          .color-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
          }
          .color-square {
            height: 80px;
            border-bottom: 1px solid #e0e0e0;
            position: relative;
            display: flex;
            align-items: flex-end;
            justify-content: center;
            padding: 5px;
            box-sizing: border-box;
          }
          .color-info {
            padding: 10px;
            text-align: center;
          }
          .color-hex {
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 5px;
          }
          .color-usage {
            font-size: 11px;
            color: #666;
          }
          .usage-badge {
            background: rgba(255,255,255,0.9);
            color: #333;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
          }
          .filter-section {
            background: #f8f9fa;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 20px;
          }
          .filter-input {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
          }
          .filter-help {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
          }
          .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
          }
          .modal-content {
            background-color: white;
            margin: 5% auto;
            padding: 20px;
            border-radius: 8px;
            width: 80%;
            max-width: 800px;
            max-height: 80vh;
            overflow-y: auto;
          }
          .close {
            color: #aaa;
            float: right;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
          }
          .close:hover {
            color: #000;
          }
          .usage-list {
            background: #f8f9fa;
            border-radius: 6px;
            padding: 15px;
            max-height: 400px;
            overflow-y: auto;
            margin-top: 15px;
          }
          .usage-item {
            padding: 8px 0;
            border-bottom: 1px solid #e0e0e0;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 12px;
          }
          .usage-item:last-child {
            border-bottom: none;
          }
          .usage-file {
            color: #3498db;
            font-weight: 600;
            margin-bottom: 3px;
          }
          .file-link {
            color: #3498db;
            text-decoration: none;
            cursor: pointer;
          }
          .file-link:hover {
            color: #2980b9;
            text-decoration: underline;
          }
          .usage-context {
            color: #666;
            background: white;
            padding: 5px;
            border-radius: 3px;
            word-break: break-all;
          }
          .empty-section {
            padding: 40px;
            text-align: center;
            color: #999;
            font-style: italic;
          }
          .pattern-count {
            background: #3498db;
            color: white;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-left: 10px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🎨 ConsiderIt Colors by Usage Pattern</h1>
          
          <div class="summary">
            <strong>Usage Pattern Analysis:</strong>
            Colors organized by how they're used throughout the codebase.
            This helps identify semantic color usage and opportunities for design system improvements.
            Click any color to see detailed usage information.
          </div>
          
          <div class="filter-section">
            <label for="fileFilter"><strong>🔍 Filter by File:</strong></label>
            <input type="text" id="fileFilter" class="filter-input" placeholder="Enter file path or pattern (e.g., banner.coffee, @client/, .css)">
            <div class="filter-help">Filter to show only colors used in files matching the pattern. Leave empty to show all colors.</div>
            
            <br><br>
            <label><strong>🎯 Variable Filter:</strong></label>
            <button id="variableFilterToggle" class="filter-button" onclick="toggleVariableFilter()" style="margin-left: 10px; padding: 8px 16px; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer;">
              Hide Variable Uses
            </button>
            <div class="filter-help">Click to hide/show colors that are already using variables (helps identify hardcoded colors that need replacement).</div>
          </div>

          <div class="tabs">
            #{generate_usage_tabs(usage_groups)}
          </div>

          #{generate_usage_tab_contents(usage_groups)}
        </div>

        <!-- Modal -->
        <div id="colorModal" class="modal">
          <div class="modal-content">
            <span class="close" onclick="closeModal()">&times;</span>
            <div id="modalContent"></div>
          </div>
        </div>

        <script>
          const usageData = #{generate_usage_data_json(usage_groups)};
          const allColorsData = #{generate_all_colors_data_json(colors)};

          function showTab(tabName) {
            // Hide all tab contents
            document.querySelectorAll('.tab-content').forEach(content => {
              content.classList.remove('active');
            });
            
            // Remove active class from all tabs
            document.querySelectorAll('.tab').forEach(tab => {
              tab.classList.remove('active');
            });
            
            // Show selected tab content
            const content = document.getElementById(tabName + '-content');
            if (content) {
              content.classList.add('active');
            }
            
            // Mark selected tab as active
            const tab = document.querySelector(`[onclick="showTab('${tabName}')"]`);
            if (tab) {
              tab.classList.add('active');
            }
            
            // Re-apply the current file filter to the new tab
            filterByFile();
          }

          function showColorDetails(hex, pattern) {
            // Get full color data for this color
            const fullHex = hex.startsWith('#') ? hex : '#' + hex;
            const colorData = allColorsData[fullHex.toLowerCase()];
            
            if (!colorData) {
              console.error('Color not found:', fullHex);
              return;
            }

            const modalContent = document.getElementById('modalContent');
            
            // Generate usage breakdown by pattern
            const usageBreakdown = {};
            let totalPatternUses = 0;
            
            // Get current file filter
            const filterValue = document.getElementById('fileFilter').value.toLowerCase().trim();
            
            Object.keys(colorData.usage_patterns).forEach(patternName => {
              const uses = colorData.usage_patterns[patternName];
              const filteredUses = filterValue ?
                uses.filter(loc => loc.file.toLowerCase().includes(filterValue)) :
                uses;
              if (filteredUses.length > 0) {
                usageBreakdown[patternName] = filteredUses.length;
                totalPatternUses += filteredUses.length;
              }
            });
            
            const usageBreakdownHtml = Object.keys(usageBreakdown)
              .sort((a, b) => usageBreakdown[b] - usageBreakdown[a])
              .map(pattern => 
                `<span style="background: #e3f2fd; color: #1976d2; padding: 2px 8px; border-radius: 12px; font-size: 12px; margin-right: 8px; margin-bottom: 4px; display: inline-block;">
                  ${pattern}: ${usageBreakdown[pattern]}
                </span>`
              ).join('');

            // Filter all locations based on file filter
            const filteredAllLocations = filterValue ?
              colorData.locations.filter(loc => loc.file.toLowerCase().includes(filterValue)) :
              colorData.locations;
            
            // Filter pattern-specific locations
            const patternLocations = colorData.usage_patterns[pattern] || [];
            const filteredPatternLocations = filterValue ?
              patternLocations.filter(loc => loc.file.toLowerCase().includes(filterValue)) :
              patternLocations;
            
            const titleSuffix = filterValue ? ` (filtered by "${filterValue}")` : '';
            
            modalContent.innerHTML = `
              <div style="display: flex; align-items: center; margin-bottom: 20px;">
                <div style="width: 60px; height: 60px; background-color: ${fullHex}; border-radius: 8px; margin-right: 20px; border: 2px solid #ddd;"></div>
                <div>
                  <h2 style="margin: 0; color: #2c3e50; font-size: 24px;">${fullHex.toUpperCase()}</h2>
                  <p style="margin: 5px 0 0 0; color: #666; font-size: 14px;">Clicked from: ${pattern} category${titleSuffix}</p>
                  ${filterValue ? `<p style="margin: 5px 0 0 0; color: #e74c3c; font-size: 12px; font-style: italic;">Showing only uses in files matching "${filterValue}"</p>` : ''}
                </div>
              </div>
              
              <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px;">
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #3498db;">
                  <div style="font-size: 12px; color: #666; margin-bottom: 5px; text-transform: uppercase; font-weight: 600;">Total Uses${filterValue ? ' (Filtered)' : ''}</div>
                  <div style="font-size: 24px; color: #2c3e50; font-weight: 600;">${filteredAllLocations.length}</div>
                </div>
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #27ae60;">
                  <div style="font-size: 12px; color: #666; margin-bottom: 5px; text-transform: uppercase; font-weight: 600;">Pattern Uses${filterValue ? ' (Filtered)' : ''}</div>
                  <div style="font-size: 24px; color: #2c3e50; font-weight: 600;">${filteredPatternLocations.length}</div>
                </div>
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #e74c3c;">
                  <div style="font-size: 12px; color: #666; margin-bottom: 5px; text-transform: uppercase; font-weight: 600;">Patterns${filterValue ? ' (Filtered)' : ''}</div>
                  <div style="font-size: 16px; color: #2c3e50; font-weight: 600;">${Object.keys(usageBreakdown).length}</div>
                </div>
              </div>
              
              <div style="margin-bottom: 20px;">
                <h3 style="color: #34495e; margin-bottom: 10px; font-size: 18px;">Usage Patterns${filterValue ? ` (filtered by "${filterValue}")` : ''}</h3>
                <div style="line-height: 1.6;">
                  ${usageBreakdownHtml || '<em style="color: #999;">No patterns found for the current filter.</em>'}
                </div>
              </div>

              <h3 style="color: #34495e; margin-bottom: 10px; font-size: 18px;">Category Usage Locations (${filteredPatternLocations.length})</h3>
              <div class="usage-list">
                ${filteredPatternLocations.length > 0 ?
                  filteredPatternLocations.map(loc => `
                    <div class="usage-item">
                      <div class="usage-file">
                        <a href="#" 
                           class="file-link" 
                           onclick="openInSublime('#{@root_path}/${loc.file}', ${loc.line}); return false;"
                           title="Click to open in Sublime Text">
                          ${loc.file}:${loc.line}
                        </a>
                      </div>
                      <div class="usage-context">${escapeHtml(loc.context)}</div>
                    </div>
                  `).join('') :
                  '<div class="usage-item" style="text-align: center; color: #999; font-style: italic;">No uses found for this pattern in the filtered files.</div>'
                }
              </div>

              <h3 style="color: #34495e; margin-bottom: 10px; font-size: 18px;">All Usage Locations (${filteredAllLocations.length})</h3>
              <div class="usage-list">
                ${filteredAllLocations.length > 0 ?
                  filteredAllLocations.map(loc => `
                    <div class="usage-item">
                      <div class="usage-file">
                        <a href="#" 
                           class="file-link" 
                           onclick="openInSublime('#{@root_path}/${loc.file}', ${loc.line}); return false;"
                           title="Click to open in Sublime Text">
                          ${loc.file}:${loc.line}
                        </a>
                      </div>
                      <div class="usage-context">${escapeHtml(loc.context)}</div>
                    </div>
                  `).join('') :
                  '<div class="usage-item" style="text-align: center; color: #999; font-style: italic;">No uses found in the filtered files.</div>'
                }
              </div>
            `;
            
            document.getElementById('colorModal').style.display = 'block';
          }

          function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
          }

          function openInSublime(filePath, lineNumber) {
            // Try to make a request to a local HTTP server that will open the file
            fetch(`http://localhost:9999/open?file=${encodeURIComponent(filePath)}&line=${lineNumber}`)
              .catch(() => {
                // Fallback: try to use subl:// URL scheme
                const sublUrl = `subl://open?url=file://${encodeURIComponent(filePath)}&line=${lineNumber}`;
                window.location.href = sublUrl;
              });
          }

          function closeModal() {
            document.getElementById('colorModal').style.display = 'none';
          }

          function filterByFile() {
            const filterValue = document.getElementById('fileFilter').value.toLowerCase().trim();
            const colorCards = document.querySelectorAll('.color-card');
            
            // Get the current active tab to know which usage pattern we're looking at
            const activeTab = document.querySelector('.tab.active');
            const currentPattern = activeTab ? activeTab.getAttribute('onclick').match(/'([^']+)'/)[1] : null;
            
            colorCards.forEach(card => {
              const colorHex = card.getAttribute('onclick').match(/'([^']+)'/)[1];
              const fullHex = '#' + colorHex;
              const colorInfo = allColorsData[fullHex.toLowerCase()];
              
              if (!filterValue) {
                // Show all if no filter - restore original counts for current pattern
                card.style.display = '';
                const badge = card.querySelector('.usage-badge');
                const usageText = card.querySelector('.color-usage');
                if (badge && colorInfo && currentPattern) {
                  const patternData = colorInfo.usage_patterns[currentPattern] || [];
                  const originalCount = patternData.length;
                  badge.textContent = originalCount;
                  usageText.textContent = `${originalCount} use${originalCount == 1 ? '' : 's'}`;
                }
                return;
              }
              
              // Calculate filtered usage count for the current pattern only
              let filteredCount = 0;
              if (colorInfo && colorInfo.usage_patterns && currentPattern) {
                const patternLocations = colorInfo.usage_patterns[currentPattern] || [];
                filteredCount = patternLocations.filter(loc => 
                  loc.file.toLowerCase().includes(filterValue)
                ).length;
              }
              
              if (filteredCount > 0) {
                // Show card and update count
                card.style.display = '';
                const badge = card.querySelector('.usage-badge');
                const usageText = card.querySelector('.color-usage');
                if (badge && usageText) {
                  badge.textContent = filteredCount;
                  usageText.textContent = `${filteredCount} use${filteredCount == 1 ? '' : 's'} (filtered)`;
                }
              } else {
                // Hide card completely
                card.style.display = 'none';
              }
            });
            
            // Update group headers and hide empty groups
            updateUsageGroupHeaders(filterValue);
            
            // Update tab counts independently (not based on current tab visibility)
            updateTabCounts(filterValue);
          }
          
          function updateUsageGroupHeaders(filterValue) {
            const groups = document.querySelectorAll('.color-group');
            
            groups.forEach(group => {
              const cards = group.querySelectorAll('.color-card');
              const visibleCards = Array.from(cards).filter(card => 
                card.style.display !== 'none'
              );
              
              const header = group.querySelector('.group-header');
              if (header && header.textContent) {
                const originalText = header.getAttribute('data-original-text') || header.textContent;
                header.setAttribute('data-original-text', originalText);
                
                if (!filterValue) {
                  header.textContent = originalText;
                } else {
                  // Calculate total filtered uses for this group
                  let totalFilteredUses = 0;
                  visibleCards.forEach(card => {
                    const badge = card.querySelector('.usage-badge');
                    if (badge) {
                      totalFilteredUses += parseInt(badge.textContent) || 0;
                    }
                  });
                  
                  const groupMatch = originalText.match(/^(.+?) \((\d+)\)$/);
                  if (groupMatch) {
                    const groupName = groupMatch[1];
                    header.textContent = `${groupName} (${visibleCards.length} - ${totalFilteredUses} uses, filtered)`;
                  }
                }
              }
              
              // Hide group if no visible cards
              if (visibleCards.length === 0) {
                group.style.display = 'none';
              } else {
                group.style.display = '';
              }
            });
          }
          
          function updateTabCounts(filterValue) {
            const tabs = document.querySelectorAll('.tab');
            
            tabs.forEach(tab => {
              const tabName = tab.getAttribute('onclick').match(/'([^']+)'/)[1];
              const countSpan = tab.querySelector('.pattern-count');
              
              if (countSpan) {
                const originalCount = tab.getAttribute('data-original-count') || countSpan.textContent;
                tab.setAttribute('data-original-count', originalCount);
                
                if (!filterValue) {
                  countSpan.textContent = originalCount;
                  tab.style.display = '';
                } else {
                  // Calculate how many colors would be visible in this specific tab for the filter
                  let filteredCount = 0;
                  
                  // Get all colors in the usage data for this pattern
                  if (usageData[tabName]) {
                    Object.keys(usageData[tabName]).forEach(colorHex => {
                      const colorInfo = allColorsData[colorHex];
                      if (colorInfo && colorInfo.usage_patterns && colorInfo.usage_patterns[tabName]) {
                        const patternLocations = colorInfo.usage_patterns[tabName] || [];
                        const hasMatchingFiles = patternLocations.some(loc => 
                          loc.file.toLowerCase().includes(filterValue)
                        );
                        if (hasMatchingFiles) {
                          filteredCount++;
                        }
                      }
                    });
                  }
                  
                  if (filteredCount > 0) {
                    countSpan.textContent = filteredCount;
                    tab.style.display = '';
                  } else {
                    tab.style.display = 'none';
                  }
                }
              }
            });
          }

          window.onclick = function(event) {
            const modal = document.getElementById('colorModal');
            if (event.target === modal) {
              closeModal();
            }
          }

          // Show first tab by default and set up filter
          document.addEventListener('DOMContentLoaded', function() {
            const firstTab = document.querySelector('.tab');
            if (firstTab) {
              firstTab.click();
            }
            
            // Add filter event listener
            const filterInput = document.getElementById('fileFilter');
            if (filterInput) {
              filterInput.addEventListener('input', filterByFile);
            }
          });

          let variableFilterActive = false;
          // Store original counts
          let originalCounts = {};

          function toggleVariableFilter() {
            variableFilterActive = !variableFilterActive;
            const button = document.getElementById('variableFilterToggle');
            
            if (variableFilterActive) {
              // Store original counts before filtering
              document.querySelectorAll('.tab').forEach(tab => {
                const onclick = tab.getAttribute('onclick');
                if (onclick) {
                  const tabMatch = onclick.match(/showTab\\('([^']+)'/);
                  if (tabMatch) {
                    const tabName = tabMatch[1];
                    const countElement = tab.querySelector('.pattern-count');
                    if (countElement) {
                      originalCounts[tabName] = countElement.textContent;
                    }
                  }
                }
              });
              
              button.textContent = 'Show Variable Uses';
              button.style.background = '#e74c3c';
            } else {
              // Restore original counts
              document.querySelectorAll('.tab').forEach(tab => {
                const onclick = tab.getAttribute('onclick');
                if (onclick) {
                  const tabMatch = onclick.match(/showTab\\('([^']+)'/);
                  if (tabMatch) {
                    const tabName = tabMatch[1];
                    const countElement = tab.querySelector('.pattern-count');
                    if (countElement && originalCounts[tabName]) {
                      countElement.textContent = originalCounts[tabName];
                    }
                  }
                }
              });
              
              button.textContent = 'Hide Variable Uses';
              button.style.background = '#3498db';
            }
            
            applyVariableFilter();
          }

          function applyVariableFilter() {
            const colorCards = document.querySelectorAll('.color-card');
            
            colorCards.forEach(card => {
              if (!variableFilterActive) {
                card.style.display = 'block';
                return;
              }
              
              // Get the color hex from the onclick attribute
              const onclick = card.getAttribute('onclick');
              if (!onclick) return;
              
              const match = onclick.match(/showColorDetails\\('([^']+)'/);
              if (!match) return;
              
              const colorHex = '#' + match[1];
              const currentTab = document.querySelector('.tab.active').getAttribute('onclick').match(/showTab\\('([^']+)'/)[1];
              
              // Check if this color has variable usage in the current tab
              const colorData = usageData[currentTab] && usageData[currentTab][colorHex];
              if (!colorData) {
                card.style.display = 'block';
                return;
              }
              
              // Check if any usage contains variable references
              const hasVariableUsage = colorData.locations.some(location => {
                const context = location.context.toLowerCase();
                // Look for common variable patterns: variables or interpolation
                return context.includes('bg_') || context.includes('text_') || context.includes('brd_') || 
                       context.includes('shadow_') || context.includes('focus_') || context.includes('selected_') ||
                       context.includes('slidergram_') || context.includes('logo_') || context.includes('attention_') ||
                       context.includes('failure_') || context.includes('success_') || context.includes('caution_') ||
                       context.includes('upgrade_') || context.includes('considerit_') ||
                       context.includes('#' + '{');
              });
              
              if (hasVariableUsage) {
                card.style.display = 'none';
              } else {
                card.style.display = 'block';
              }
            });
            
            // Update tab counts when filter is active
            updateTabCounts();
          }

          function updateTabCounts() {
            document.querySelectorAll('.tab').forEach(tab => {
              const tabName = tab.getAttribute('onclick').match(/showTab\\('([^']+)'/)[1];
              const countElement = tab.querySelector('.pattern-count');
              if (!countElement) return;
              
              if (!variableFilterActive) {
                // Restore original count when filter is off
                const originalCount = tab.getAttribute('data-original-count');
                if (originalCount) {
                  countElement.textContent = originalCount;
                }
                return;
              }
              
              // Calculate filtered count for this specific tab
              let filteredCount = 0;
              
              // Get all colors in the usage data for this pattern
              if (usageData[tabName]) {
                Object.keys(usageData[tabName]).forEach(colorHex => {
                  const colorInfo = usageData[tabName][colorHex];
                  if (colorInfo && colorInfo.locations) {
                    // Check if this color has variable usage
                    const hasVariableUsage = colorInfo.locations.some(location => {
                      const context = location.context.toLowerCase();
                      return context.includes('bg_') || context.includes('text_') || context.includes('brd_') || 
                             context.includes('shadow_') || context.includes('focus_') || context.includes('selected_') ||
                             context.includes('slidergram_') || context.includes('logo_') || context.includes('attention_') ||
                             context.includes('failure_') || context.includes('success_') || context.includes('caution_') ||
                             context.includes('upgrade_') || context.includes('considerit_') ||
                             context.includes('#' + '{');
                    });
                    
                    // Only count colors that DON'T have variable usage
                    if (!hasVariableUsage) {
                      filteredCount++;
                    }
                  }
                });
              }
              
              countElement.textContent = filteredCount;
            });
          }

          // Apply variable filter when switching tabs
          const originalShowTab = showTab;
          showTab = function(tabName) {
            originalShowTab(tabName);
            if (variableFilterActive) {
              setTimeout(applyVariableFilter, 10);
            }
          };
        </script>
      </body>
      </html>
    HTML

    html
  end

  def generate_usage_tabs(usage_groups)
    pattern_labels = {
      background: '🎨 Background',
      text: '📝 Text',
      border: '🔲 Border',
      shadow: '🌫️ Shadow',
      fill: '🎯 Fill',
      stroke: '✏️ Stroke',
      outline: '⭕ Outline',
      icon: '🔧 Icons',
      variable_definition: '📝 Variables',
      svg_element: '🖼️ SVG',
      gradient: '🌈 Gradients',
      function_parameter: '🔧 Functions',
      config_property: '⚙️ Config',
      custom_property: '🔗 Properties',
      other: '❓ Other'
    }

    usage_groups.map do |pattern, colors|
      count = colors.length
      active_class = pattern == :background ? ' active' : ''
      
      "<button class=\"tab#{active_class}\" onclick=\"showTab('#{pattern}')\">" +
      "#{pattern_labels[pattern]}" +
      "<span class=\"pattern-count\">#{count}</span>" +
      "</button>"
    end.join("\n")
  end

  def generate_usage_tab_contents(usage_groups)
    pattern_descriptions = {
      background: 'Colors used for background-color, backgroundColor, and background properties.',
      text: 'Colors used for the color property (text color).',
      border: 'Colors used for border, border-color, and related border properties.',
      shadow: 'Colors used in box-shadow, text-shadow, and drop-shadow properties.',
      fill: 'Colors used for SVG fill properties.',
      stroke: 'Colors used for SVG stroke properties.',
      outline: 'Colors used for outline and outline-color properties.',
      icon: 'Colors passed to icon functions (trash_icon, edit_icon, etc.).',
      variable_definition: 'Colors defined as global variables (window.color_name = ...).',
      svg_element: 'Colors used directly in SVG element attributes.',
      gradient: 'Colors used in CSS gradients (linear-gradient, radial-gradient).',
      function_parameter: 'Colors passed as parameters to functions (cssTriangle, etc.).',
      config_property: 'Colors assigned to configuration object properties.',
      custom_property: 'Colors assigned to custom properties and configuration objects.',
      other: 'Colors that don\'t fit into the above categories.'
    }

    usage_groups.map do |pattern, colors|
      active_class = pattern == :background ? ' active' : ''
      
      content = if colors.empty?
        "<div class=\"empty-section\">No colors found for this usage pattern.</div>"
      else
        # Group colors into 4 categories: gray/non-gray × alpha/no-alpha
        gray_colors_no_alpha = {}
        gray_colors_with_alpha = {}
        non_gray_colors_no_alpha = {}
        non_gray_colors_with_alpha = {}
        
        colors.each do |hex, data|
          is_gray = is_gray_color?(hex)
          has_alpha = has_alpha_channel?(hex)
          
          if is_gray && has_alpha
            gray_colors_with_alpha[hex] = data
          elsif is_gray && !has_alpha
            gray_colors_no_alpha[hex] = data
          elsif !is_gray && has_alpha
            non_gray_colors_with_alpha[hex] = data
          else # !is_gray && !has_alpha
            non_gray_colors_no_alpha[hex] = data
          end
        end
        
        # Sort each group by similarity (hue for non-grays, lightness+alpha for grays)
        sorted_gray_no_alpha = gray_colors_no_alpha.sort_by { |hex, _| color_lightness(hex) }
        sorted_gray_with_alpha = gray_colors_with_alpha.sort_by { |hex, _| get_gray_sort_key(hex) }
        sorted_non_gray_no_alpha = non_gray_colors_no_alpha.sort_by { |hex, _| color_hue(hex) }
        sorted_non_gray_with_alpha = non_gray_colors_with_alpha.sort_by { |hex, _| color_hue(hex) }
        
        # Generate color cards for each group
        gray_no_alpha_section = if sorted_gray_no_alpha.any?
          gray_cards = sorted_gray_no_alpha.map do |hex, data|
            generate_color_card(hex, data, pattern)
          end.join("")
          
          "<div class=\"color-group\">" +
          "<h4 class=\"group-header\">🔘 Gray Colors (#{sorted_gray_no_alpha.length})</h4>" +
          "<div class=\"color-grid\">#{gray_cards}</div>" +
          "</div>"
        else
          ""
        end
        
        gray_with_alpha_section = if sorted_gray_with_alpha.any?
          gray_alpha_cards = sorted_gray_with_alpha.map do |hex, data|
            generate_color_card(hex, data, pattern)
          end.join("")
          
          "<div class=\"color-group\">" +
          "<h4 class=\"group-header\">🔘🟨 Gray Colors with Alpha (#{sorted_gray_with_alpha.length})</h4>" +
          "<div class=\"color-grid\">#{gray_alpha_cards}</div>" +
          "</div>"
        else
          ""
        end
        
        non_gray_no_alpha_section = if sorted_non_gray_no_alpha.any?
          non_gray_cards = sorted_non_gray_no_alpha.map do |hex, data|
            generate_color_card(hex, data, pattern)
          end.join("")
          
          "<div class=\"color-group\">" +
          "<h4 class=\"group-header\">🌈 Non-Gray Colors (#{sorted_non_gray_no_alpha.length})</h4>" +
          "<div class=\"color-grid\">#{non_gray_cards}</div>" +
          "</div>"
        else
          ""
        end
        
        non_gray_with_alpha_section = if sorted_non_gray_with_alpha.any?
          non_gray_alpha_cards = sorted_non_gray_with_alpha.map do |hex, data|
            generate_color_card(hex, data, pattern)
          end.join("")
          
          "<div class=\"color-group\">" +
          "<h4 class=\"group-header\">🌈🟨 Non-Gray Colors with Alpha (#{sorted_non_gray_with_alpha.length})</h4>" +
          "<div class=\"color-grid\">#{non_gray_alpha_cards}</div>" +
          "</div>"
        else
          ""
        end
        
        gray_no_alpha_section + gray_with_alpha_section + non_gray_no_alpha_section + non_gray_with_alpha_section
      end

      "<div id=\"#{pattern}-content\" class=\"tab-content#{active_class}\">#{content}</div>"
    end.join("\n")
  end

  def generate_color_card(hex, data, pattern)
    files_used = data[:locations].map { |loc| loc[:file] }.uniq.join(';')
    "<div class=\"color-card\" data-files=\"#{files_used}\" onclick=\"showColorDetails('#{hex.gsub('#', '')}', '#{pattern}')\">" +
    "<div class=\"color-square\" style=\"background-color: #{hex}\">" +
    "<div class=\"usage-badge\">#{data[:usage_count]}</div>" +
    "</div>" +
    "<div class=\"color-info\">" +
    "<div class=\"color-hex\">#{hex.upcase}</div>" +
    "<div class=\"color-usage\">#{data[:usage_count]} use#{data[:usage_count] == 1 ? '' : 's'}</div>" +
    "</div>" +
    "</div>"
  end

  def is_gray_color?(hex)
    # Convert hex to RGB
    r, g, b = hex_to_rgb(hex)
    
    # Check if it's approximately gray (R, G, B values are similar)
    max_diff = [r - g, r - b, g - b].map(&:abs).max
    max_diff <= 15  # Allow small differences for colors like #f7f7f7
  end

  def has_alpha_channel?(hex)
    # Remove the # and check if it's 8 characters (includes alpha)
    hex.gsub('#', '').length == 8
  end

  def color_lightness(hex)
    r, g, b = hex_to_rgb(hex)
    # Calculate relative luminance
    (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
  end

  def color_hue(hex)
    r, g, b = hex_to_rgb(hex)
    r, g, b = r / 255.0, g / 255.0, b / 255.0
    
    max = [r, g, b].max
    min = [r, g, b].min
    diff = max - min
    
    return 0 if diff == 0
    
    case max
    when r
      h = (60 * ((g - b) / diff) + 360) % 360
    when g
      h = (60 * ((b - r) / diff) + 120) % 360
    when b
      h = (60 * ((r - g) / diff) + 240) % 360
    end
    
    h
  end

  def hex_to_rgb(hex)
    hex = hex.gsub('#', '')
    # Handle both 6-character and 8-character hex codes
    return [0, 0, 0] if hex.length != 6 && hex.length != 8
    
    [
      hex[0..1].to_i(16),
      hex[2..3].to_i(16),
      hex[4..5].to_i(16)
    ]
  end

  def generate_usage_data_json(usage_groups)
    data = {}
    
    usage_groups.each do |pattern, colors|
      data[pattern] = {}
      colors.each do |hex, color_data|
        data[pattern][hex.downcase] = {
          hex: hex,
          data: color_data[:data],
          usage_count: color_data[:usage_count],
          locations: color_data[:locations]
        }
      end
    end
    
    JSON.generate(data)
  end

  def generate_all_colors_data_json(colors)
    data = {}
    
    colors.each do |hex, color_data|
      data[hex.downcase] = {
        hex: hex,
        count: color_data[:count],
        locations: color_data[:locations],
        types: color_data[:types].to_a,
        originals: color_data[:originals].to_a,
        usage_patterns: color_data[:usage_patterns]
      }
    end
    
    JSON.generate(data)
  end
end

# Run the analysis
if __FILE__ == $0
  root_path = ARGV[0] || Dir.pwd
  
  unless Dir.exist?(root_path)
    puts "❌ Directory not found: #{root_path}"
    puts "Usage: ruby color_analysis.rb [path_to_codebase]"
    exit 1
  end
  
  analyzer = ColorAnalyzer.new(root_path)
  analyzer.analyze
  
  puts
  puts "🎉 Color analysis complete!"
  puts "📋 Check the color_analysis_output/ directory for detailed reports"
  puts "💡 Start with consolidation_suggestions.md for actionable recommendations"
end
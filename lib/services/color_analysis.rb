#!/usr/bin/env ruby

require 'find'
require 'json'
require 'csv'

# Color Analysis Tool for ConsiderIt
# This script extracts all colors used throughout the codebase and groups them by similarity

class ColorAnalyzer
  COLOR_PATTERNS = {
    # Hex colors: #fff, #ffffff, #123456
    hex: /#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b/,
    
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

  def initialize(root_path)
    @root_path = root_path
    @colors_found = {}
    @file_extensions = %w[.coffee .css .js .scss .sass]
  end

  def analyze
    puts "🎨 Starting color analysis of ConsiderIt codebase..."
    puts "📁 Scanning directory: #{@root_path}"
    
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
      "@client/histogram-legacy.coffee"
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
          record_color(hex_color, line.strip, file_path, line_number, 'hex') if hex_color
        end
        
        # Extract RGB colors
        line.scan(COLOR_PATTERNS[:rgb]) do |r, g, b, a|
          next if r.nil? || g.nil? || b.nil?
          hex_color = rgb_to_hex(r.to_i, g.to_i, b.to_i)
          alpha = a ? ", alpha: #{a}" : ""
          original = "rgb#{a ? 'a' : ''}(#{r},#{g},#{b}#{a ? ",#{a}" : ''})"
          record_color(hex_color, line.strip, file_path, line_number, 'rgb', original, alpha)
        end
        
        # Extract HSL colors
        line.scan(COLOR_PATTERNS[:hsl]) do |h, s, l, a|
          next if h.nil? || s.nil? || l.nil?
          hex_color = hsl_to_hex(h.to_i, s.to_i, l.to_i)
          alpha = a ? ", alpha: #{a}" : ""
          original = "hsl#{a ? 'a' : ''}(#{h},#{s}%,#{l}%#{a ? ",#{a}" : ''})"
          record_color(hex_color, line.strip, file_path, line_number, 'hsl', original, alpha)
        end
        
        # Extract named colors
        line.scan(COLOR_PATTERNS[:named]) do |match|
          next if match.nil?
          color_name = match.to_s.downcase.strip
          next if color_name.empty?
          next unless NAMED_COLORS.key?(color_name)
          
          hex_color = NAMED_COLORS[color_name]
          record_color(hex_color, line.strip, file_path, line_number, 'named', color_name)
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

  def record_color(hex_color, line_content, file_path, line_number, type, original = nil, alpha = nil)
    # Skip if it's just a fragment of a larger hex number (like in URLs)
    return if hex_color.length > 7 # Skip malformed colors
    
    color_key = hex_color.downcase
    
    @colors_found[color_key] ||= {
      hex: hex_color,
      count: 0,
      locations: [],
      types: Set.new,
      originals: Set.new
    }
    
    @colors_found[color_key][:count] += 1
    @colors_found[color_key][:types] << type
    @colors_found[color_key][:originals] << (original || hex_color)
    
    # Store all location info for HTML report
    relative_path = file_path.gsub(@root_path, '').gsub(/^\//, '')
    @colors_found[color_key][:locations] << {
      file: relative_path,
      line: line_number,
      context: line_content.strip[0, 100] + (line_content.length > 100 ? '...' : ''),
      alpha: alpha
    }
  end

  def normalize_hex(hex)
    return nil if hex.nil? || hex.length < 4
    
    # Convert 3-digit hex to 6-digit
    if hex.length == 4 # #abc
      hex = "##{hex[1]}#{hex[1]}#{hex[2]}#{hex[2]}#{hex[3]}#{hex[3]}"
    end
    
    # Ensure it's a valid hex color
    return nil if hex.length != 7 || !hex.match(/^#[0-9a-fA-F]{6}$/)
    
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
    return [0, 0, 0] if hex.length != 6
    
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
    valid_colors = @colors_found.reject { |hex, _| hex == 'transparent' || hex.length != 7 }
    
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
      # For grays, sort by brightness (dark to light)
      group.sort_by { |item| get_brightness(item[:hex]) }
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
            background: #e0e0e0;
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
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🎨 ConsiderIt Color Analysis - Interactive Report</h1>
          
          <div class="summary">
            <strong>Analysis Summary:</strong>
            #{grouped_colors.flatten.length} unique colors found across the codebase.
            Colors are grouped by similarity and separated into grays and non-grays.
            Click any color square to see detailed usage information.
          </div>
    HTML

    # Gray colors section
    if gray_groups.any?
      html += <<~HTML
        <h2><span class="emoji">🔘</span> Gray Colors (#{gray_groups.length} groups)</h2>
      HTML
      
      gray_groups.each_with_index do |group, group_index|
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
          
          html += <<~HTML
            <div class="color-square #{is_dark ? 'dark' : ''}" 
                 style="background-color: #{hex}" 
                 onclick="showColorDetails('#{hex.gsub('#', '')}')">
              <div class="color-label">#{data[:count]}</div>
            </div>
          HTML
        end
        
        html += "</div></div>"
      end
    end

    # Non-gray colors section  
    if non_gray_groups.any?
      html += <<~HTML
        <h2><span class="emoji">🌈</span> Non-Gray Colors (#{non_gray_groups.length} groups)</h2>
      HTML
      
      non_gray_groups.each_with_index do |group, group_index|
        total_count = group.sum { |item| item[:data][:count] }
        
        # Check if this is the last group and has many different colors (likely miscellaneous)
        is_misc_group = group_index == non_gray_groups.length - 1 && group.length > 3
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
          
          html += <<~HTML
            <div class="color-square #{is_dark ? 'dark' : ''}" 
                 style="background-color: #{hex}" 
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

            const modalContent = document.getElementById('modalContent');
            const isDark = isColorDark(hex);
            
            modalContent.innerHTML = `
              <div class="color-info">
                <div class="color-preview" style="background-color: ${hex}; border-color: ${isDark ? '#fff' : '#000'}"></div>
                <div class="color-details">
                  <h3>${hex}</h3>
                  <p><strong>Usage:</strong> ${colorInfo.count} times across ${colorInfo.locations.length} locations</p>
                </div>
              </div>
              
              <div class="color-stats">
                <div class="stat-box">
                  <div class="stat-label">Total Uses</div>
                  <div class="stat-value">${colorInfo.count}</div>
                </div>
                <div class="stat-box">
                  <div class="stat-label">Locations</div>
                  <div class="stat-value">${colorInfo.locations.length}</div>
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
              
              <h4>All Usages (${colorInfo.locations.length} locations):</h4>
              <div class="usage-list">
                ${colorInfo.locations.map(loc => `
                  <div class="usage-item">
                    <div class="usage-file">${loc.file}:${loc.line}</div>
                    <div class="usage-context">${escapeHtml(loc.context)}</div>
                  </div>
                `).join('')}
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

          function closeModal() {
            document.getElementById('colorModal').style.display = 'none';
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
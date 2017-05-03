#!/usr/bin/env ruby

require 'net/https'
require 'json'
require 'fileutils'

abort "Usage\n #$0 path PAT" unless ARGV.size == 2
path, $pat = ARGV

uri = URI.parse 'https://app.asana.com'
$http = Net::HTTP.new(uri.host, uri.port)
$http.use_ssl = true
$http.verify_mode = OpenSSL::SSL::VERIFY_PEER

def asana path
    req = Net::HTTP::Get.new('/api/1.0' + path, { 'Content-Type' => 'application-json' })
    req.basic_auth($pat, '')
    res = $http.start { |http| $http.request(req) }

    return (JSON.parse(res.body))  if res.code >= '200' 

    p res.message
    p res.body
    abort
end    


asana('/projects')['data'].each do |project|
  dir = File.join(path, project['name'].gsub(/\W/,'_'))
  puts dir
  FileUtils.mkdir_p dir

  id = project['id']
  proj = asana "/projects/#{id}"
  File.open("#{dir}/project.json", 'w') {|f| f.puts JSON.pretty_generate(proj) }
  tasks = asana "/projects/#{id}/tasks"

  File.open("#{dir}/tasks.json", 'w') {|f| f.puts JSON.pretty_generate(tasks) } 
  tasks['data'].each do |task|
    task_dir = File.join(dir, task['name'].gsub(/\W/,'_'))
    FileUtils.mkdir_p task_dir

    tsk = asana "/tasks/#{task['id']}"
    File.open("#{task_dir}/task.json", 'w') {|f| f.puts JSON.pretty_generate(tsk) } 

    stories = asana "/tasks/#{task['id']}/stories"   
    File.open("#{task_dir}/stories.json", 'w') {|f| f.puts JSON.pretty_generate(stories) }
    attachements = stories['data'].find_all {|story| story['text'] =~ /^attached/ }
    attachements.each {|att| puts "#{task_dir} : #{att['text']}" }
  end
end


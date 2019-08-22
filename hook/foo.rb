r = Nginx::Request.new
r.content_type = "text/html"

Docker::Container.expire_cache!
me = Docker::Container.me!
containers = Docker::Container.all - [me]

not_connected_networks = (containers.flat_map(&:networks) - me.networks)
not_connected_networks.each do |n|
  n.connect(me)
end
if not_connected_networks.any?
  Docker::Container.expire_cache!
  me = Docker::Container.me!
  containers = Docker::Container.all - [me]
end
containers = containers.select {|c| c.reachable_from?(me) }.sort_by(&:name)

Nginx.echo <<-HTML
    #{
      containers.flat_map do |c|
        me.exposed_ports.select {|_, local| c.listening?(me, local) }.map do |remote, local|
          "<li><a href='#{c.uri(remote)}' target='_blank'>#{c.name} (#{remote}:#{local})</a></li>"
        end
      end.join("\n")
    }
HTML

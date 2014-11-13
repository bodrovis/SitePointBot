module Lita
  module Handlers
    class Reminder < Handler
      config :server

      route(/^remind plz$/, :index, command: true, help: { "remind plz" => "Remind about your todos." })

      route(/^todo\s+(.+)$/, :create, command: true, help: { "todo TODO" => "Adds new todo to the list." })

      route(/^done todo\s+(\d+)$/, :destroy, command: true, help: { "done todo TODO_ID" => "Marks todo with the specified number as done." })

      def index(response)
        todos = parse get("#{config.server}/todos.json")
        if todos.any?
          response.reply("Your todos:")
          todos.each do |todo|
            response.reply("# #{todo['id']}: #{todo['title']}")
          end
        else
          response.reply('You have done all the todos! Good job!')
        end
      end

      def create(response)
        todo = response.match_data[1]
        result = post "#{config.server}/todos.json", 'todo[title]' => todo
        if result.code.to_i.success?
          response.reply("#{todo} was added.")
        else
          response.reply("I've encountered the following errors while saving your todo: #{parse(result.body)}")
        end
      end

      def destroy(response)
        todo_id = response.match_data[1]
        result = delete "#{config.server}/todos/#{todo_id}.json"
        if result.code.to_i.success?
          response.reply("Todo # #{todo_id} was marked as done.")
        else
          response.reply("I've encountered an error while marking your todo as done.")
        end
      end

      private

      def post(url, data = {})
        Net::HTTP.post_form(make_uri(url), data)
      end

      def get(url)
        Net::HTTP.get make_uri(url)
      end

      def delete(url)
        uri = make_uri(url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Delete.new(uri.path)
        http.request(request)
      end

      def make_uri(url)
        URI(url)
      end

      def parse(obj)
        MultiJson.load(obj)
      end
    end

    Lita.register_handler(Reminder)
  end
end

class Numeric
  def success?
    self > 199 && self < 300
  end
end
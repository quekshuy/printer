require "backend_server/base"
require "remote_printer"

class BackendServer::Polling < BackendServer::Base
  get "/:printer_id" do
    printer = RemotePrinter.find(params["printer_id"])
    printer.update(remote_printer_params(params))
    printer.data_to_print
  end

  private

  def remote_printer_params(params)
    type = env["HTTP_ACCEPT"] ? env["HTTP_ACCEPT"].split("application/vnd.freerange.printer.").last : nil
    {type: type, ip: request.ip}
  end
end
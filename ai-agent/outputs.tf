output "instance_ip" {
  value       = aws_instance.main.public_ip
  description = "Public IP address of the instance"
}

output "ssh_command" {
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_instance.main.public_ip}"
  description = "SSH command to connect to the instance"
}

output "ebs_volume_id" {
  value       = aws_ebs_volume.data.id
  description = "ID of the EBS data volume"
}

output "data_mount_point" {
  value       = "/data"
  description = "Mount point for the EBS volume"
}

output "ollama_api_url" {
  value       = "http://${aws_instance.main.public_ip}:11434"
  description = "Ollama API endpoint URL"
}

output "test_ollama_command" {
  value       = "curl http://${aws_instance.main.public_ip}:11434/api/tags"
  description = "Command to test Ollama API"
}

output "langchain_connection_info" {
  value = <<-EOT
    Connect with LangChain:
    
    from langchain_community.llms import Ollama
    
    llm = Ollama(
        model="llama3",
        base_url="http://${aws_instance.main.public_ip}:11434"
    )
    
    response = llm.invoke("Hello, how are you?")
    print(response)
  EOT
  description = "Example LangChain connection code"
}
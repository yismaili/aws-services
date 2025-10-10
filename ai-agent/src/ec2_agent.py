"""
AI Agent to generate Terraform configuration for EC2 instances
Uses Ollama LLM to understand requirements and generate Terraform code
"""

import json
import os
from langchain_community.llms import Ollama
from langchain.prompts import PromptTemplate
from langchain.chains import LLMChain

class EC2TerraformAgent:
    def __init__(self, ollama_host="http://localhost:11434"):
        """Initialize the agent with Ollama connection"""
        self.llm = Ollama(
            model="llama3",
            base_url=ollama_host,
            temperature=0.1
        )
        
        self.prompt_template = PromptTemplate(
            input_variables=["user_request"],
            template="""You are a Terraform expert. Generate Terraform configuration based on user requirements.

User Request: {user_request}

Generate a complete Terraform configuration for AWS EC2 instances. Include:
1. Provider configuration
2. Data source for Ubuntu AMI
3. Security group (SSH on port 22, HTTP on port 80)
4. EC2 instances with the requested specifications
5. Outputs showing instance IPs

Important:
- Use variables where appropriate
- Follow Terraform best practices
- Include helpful comments
- Make it ready to use with 'terraform apply'

Generate ONLY the Terraform code, no explanations before or after. Start with 'terraform {{' and end with the last closing brace."""
        )
        
        self.chain = LLMChain(llm=self.llm, prompt=self.prompt_template)
    
    def parse_requirements(self, user_input):
        """Parse user input to extract requirements"""
        parse_prompt = f"""Extract the following information from this request:
Request: "{user_input}"

Provide a JSON response with these fields:
- instance_count: number of EC2 instances (integer)
- instance_type: EC2 instance type (e.g., t3.small, t3.medium)
- region: AWS region (default: us-east-1)
- project_name: name for the project

Return ONLY valid JSON, nothing else.
"""
        
        response = self.llm.invoke(parse_prompt)
        
        try:
            # Extract JSON from response
            start = response.find('{')
            end = response.rfind('}') + 1
            json_str = response[start:end]
            requirements = json.loads(json_str)
            return requirements
        except:
            return {
                "instance_count": 2,
                "instance_type": "t3.small",
                "region": "us-east-1",
                "project_name": "my-ec2-project"
            }
    
    def generate_terraform_config(self, requirements):
        """Generate Terraform configuration based on requirements"""
        user_request = f"""
Create {requirements['instance_count']} EC2 instances with the following specs:
- Instance type: {requirements['instance_type']}
- Region: {requirements['region']}
- Project name: {requirements['project_name']}
- OS: Ubuntu 22.04
- Include SSH access and HTTP access
"""
        
        terraform_code = self.chain.run(user_request=user_request)
        return terraform_code
    
    def save_config(self, config, filename="generated_main.tf"):
        """Save generated configuration to file"""
        with open(filename, 'w') as f:
            f.write(config)
        print(f"✓ Configuration saved to {filename}")
    
    def generate_tfvars(self, requirements, filename="generated.tfvars"):
        """Generate terraform.tfvars file"""
        tfvars_content = f"""# Generated terraform.tfvars
aws_region = "{requirements['region']}"
project_name = "{requirements['project_name']}"
instance_type = "{requirements['instance_type']}"
instance_count = {requirements['instance_count']}

# SSH key paths (update these to match your keys)
ssh_public_key_path = "~/.ssh/id_rsa.pub"
ssh_private_key_path = "~/.ssh/id_rsa"
"""
        
        with open(filename, 'w') as f:
            f.write(tfvars_content)
        print(f"✓ Variables saved to {filename}")
    
    def generate_commands(self, requirements):
        """Generate the commands needed to deploy"""
        commands = f"""
# Terraform Deployment Commands
# ==============================

# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Preview changes
terraform plan

# 4. Apply configuration (create {requirements['instance_count']} EC2 instances)
terraform apply -auto-approve

# 5. Show outputs (IPs and connection info)
terraform output

# 6. Destroy resources (when done)
# terraform destroy -auto-approve
"""
        return commands
    
    def run(self, user_input):
        """Main method to run the agent"""
        print("=" * 60)
        print("EC2 Terraform Agent")
        print("=" * 60)
        
        print(f"\n📝 Your request: {user_input}")
        
        print("\n🔍 Analyzing requirements...")
        requirements = self.parse_requirements(user_input)
        print(f"✓ Understood:")
        print(f"  - Instances: {requirements['instance_count']}")
        print(f"  - Type: {requirements['instance_type']}")
        print(f"  - Region: {requirements['region']}")
        print(f"  - Project: {requirements['project_name']}")
        
        print("\n🤖 Generating Terraform configuration...")
        terraform_config = self.generate_terraform_config(requirements)
        self.save_config(terraform_config)
        
        print("\n📋 Generating variables file...")
        self.generate_tfvars(requirements)
        
        print("\n📜 Generating deployment commands...")
        commands = self.generate_commands(requirements)
        
        with open("DEPLOYMENT_COMMANDS.txt", 'w') as f:
            f.write(commands)
        print("✓ Commands saved to DEPLOYMENT_COMMANDS.txt")
        
        print("\n" + "=" * 60)
        print("✅ READY TO DEPLOY!")
        print("=" * 60)
        print("\nNext steps:")
        print("1. Review generated_main.tf")
        print("2. Update SSH key paths in generated.tfvars")
        print("3. Run: terraform init")
        print("4. Run: terraform apply")
        print("\n" + commands)


def main():
    """Interactive CLI for the agent"""
    print("=" * 60)
    print("🤖 EC2 Terraform Agent - Interactive Mode")
    print("=" * 60)
    
    ollama_host = input("\nEnter Ollama API URL (or press Enter for localhost): ").strip()
    if not ollama_host:
        ollama_host = "http://localhost:11434"
    
    try:
        agent = EC2TerraformAgent(ollama_host=ollama_host)
        print("✓ Connected to Ollama")
    except Exception as e:
        print(f"❌ Error connecting to Ollama: {e}")
        return
    
    print("\n" + "=" * 60)
    print("Examples:")
    print("  - 'I need 3 t3.medium EC2 instances in us-west-2'")
    print("  - 'Create 5 small instances for testing'")
    print("  - 'I want 2 t3.large instances in eu-west-1 for my web app'")
    print("=" * 60)
    
    user_input = input("\n🗣️  What EC2 instances do you need? ").strip()
    
    if not user_input:
        print("❌ No input provided. Exiting.")
        return
    
    agent.run(user_input)


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        user_request = " ".join(sys.argv[1:])
        ollama_host = os.getenv("OLLAMA_HOST", "http://localhost:11434")
        
        agent = EC2TerraformAgent(ollama_host=ollama_host)
        agent.run(user_request)
    else:
        main()
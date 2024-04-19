import click
import yaml

def generate_compose(base, emulators):
    # add internal network for all emulators and dependencies
    for emulator in emulators:
        emulators[emulator]['networks'] = ['br-internal']
        emulators[emulator]['depends_on'] = ['nginx']
        
    # delete the ports option from all emulators and add it to the base nginx reverse proxy
    for emulator in emulators:
        ports_option = emulators[emulator]['ports'] 
        del emulators[emulator]['ports']
        
        if 'ports' not in base['services']['nginx']:
            base['services']['nginx']['ports'] = []
        
        base['services']['nginx']['ports'] += ports_option
    
    # add all emulators to the base object
    base['services'].update(emulators)
    base['services']['restarter']['depends_on'] = list(emulators.keys())
    
    return base


def build_nginx_config(emulators):
    config_str = "events {}\n"
    config_str += "stream {\n"
    
    # group per port
    port_idx = {}
    for emulator in emulators:
        if 'emulator' not in emulator:
            continue
        
        for port_tuple in emulators[emulator]['ports']:
            port = port_tuple.split(':')[0]
            if port not in port_idx:
                port_idx[port] = []
            port_idx[port].append(emulator)
    
    for port in port_idx:
        config_str += f"\tserver {{\n"
        config_str += f"\t\tlisten {port};\n"
        config_str += f"\t\tproxy_pass emulators-{port};\n"    
        config_str += f"\t}}\n"
        
        config_str += f"\tupstream  {{\n"
        config_str += f"\t\thash $binary_remote_addr consistent;\n"
        
        for emulator in port_idx[port]:
            config_str += f"\t\tserver {emulators[emulator]['hostname']}:{port};\n"
        
        config_str += f"\t}}\n"
    
    config_str += "}\n"
    
    return config_str
        
    

@click.command()
@click.argument('--emulators-yaml', nargs=1, type=click.Path(exists=True))
def setup_compose(__emulators_yaml):
    with open(__emulators_yaml) as f:
        _emulators = yaml.load(f, yaml.Loader)
        base = yaml.load(open('./template/base.yml'), yaml.Loader)
        # standardize the service-name and hostname for all emulators
        emulators = {f'emulator-{i}': _emulators[emulator] for i, emulator in enumerate(_emulators)}
        for emulator in emulators:
            emulators[emulator]['hostname'] = emulator
            
        # create the nginx configuration file
        nginx_cfg = build_nginx_config(emulators)

        docker_compose = generate_compose(base, emulators)
        
        # write the docker-compose.yml file
        with open('compose.yml', 'w') as f:
            yaml.dump(docker_compose, f, Dumper=yaml.Dumper, sort_keys=False)
        
        # write the nginx configuration file
        with open('nginx.conf', 'w') as f:
            f.write(nginx_cfg)
        
            
if __name__ == '__main__':
    setup_compose()
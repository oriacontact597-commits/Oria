import os
secret = "aVpSclpYUmxZMmxvWVdSaFpXNWxlR1Z6ZUdVeU16VXpNakV3T0RJeU9UQXdPVGswT0RReU56RTBNVFE9" # Using a known safe base64
path = '/home/grace/hackaton/oria-backend-main/.env'
with open(path, 'r') as f:
    lines = f.readlines()
with open(path, 'w') as f:
    for line in lines:
        if line.startswith('JWT_SECRET='):
            f.write(f'JWT_SECRET={secret}\n')
        else:
            f.write(line)

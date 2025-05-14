require 'sinatra'
require 'erb'
require 'uri'

enable :sessions

class Usuario
  attr_accessor :nome, :email, :senha, :tipo, :telefone, :cpf, :saldo

  def initialize(nome, email, senha, tipo, telefone = '', cpf = '', saldo = 0)
    @nome = nome
    @email = email
    @senha = senha
    @tipo = tipo
    @telefone = telefone
    @cpf = cpf
    @saldo = saldo.to_f
  end

  def verificar_senha(senha)
    @senha == senha
  end
end

USUARIOS = {}
USUARIOS['admin@admin.com'] = Usuario.new('Administrador', 'admin@admin.com', 'admin123', 'adm')

helpers do
  def logado?
    !!session[:usuario]
  end

  def usuario_atual
    USUARIOS[session[:usuario]]
  end

  def admin?
    usuario_atual&.tipo == 'adm'
  end
end

get '/' do
  redirect '/login'
end

get '/login' do
  erb :login
end

post '/login' do
  email = params[:email]
  senha = params[:senha]
  usuario = USUARIOS[email]

  if usuario && usuario.verificar_senha(senha)
    session[:usuario] = email
    redirect '/painel'
  else
    @erro = 'Email ou senha incorretos.'
    erb :login
  end
end

get '/painel' do
  redirect '/login' unless logado?
  erb admin? ? :painel_admin : :painel_cliente
end

get '/logout' do
  session.clear
  redirect '/login'
end

get '/admin/cadastrar_cliente' do
  halt(redirect '/login') unless logado?
  halt(erb :painel_cliente) unless admin?

  erb :cadastro_cliente
end

post '/admin/cadastrar_cliente' do
  halt(redirect '/login') unless logado?
  halt(erb :painel_cliente) unless admin?

  nome = params[:nome]
  email = params[:email]
  senha = params[:senha]

  if USUARIOS.key?(email)
    @erro = 'Email já cadastrado.'
  else
    USUARIOS[email] = Usuario.new(nome, email, senha, 'cliente')
    @sucesso = 'Cliente cadastrado com sucesso!'
  end

  erb :cadastro_cliente
end

get '/admin/clientes' do
  halt(redirect '/login') unless logado?
  halt(erb :painel_cliente) unless admin?

  @clientes = USUARIOS.values.select { |u| u.tipo == 'cliente' }
  erb :lista_clientes
end

get '/admin/editar' do
  halt(redirect '/login') unless logado?
  halt(erb :painel_cliente) unless admin?

  email = params[:email]
  @cliente = USUARIOS[email]
  if @cliente.nil?
    @erro = "Cliente não encontrado."
    redirect '/admin/clientes'
  else
    erb :editar_cliente
  end
end

post '/admin/editar' do
  halt(redirect '/login') unless logado?
  halt(erb :painel_cliente) unless admin?

  email = params[:email]
  cliente = USUARIOS[email]

  if cliente
    cliente.nome     = params[:nome]
    cliente.telefone = params[:telefone]
    cliente.cpf      = params[:cpf]
    cliente.saldo    = params[:saldo].to_f
    @sucesso = "Cliente atualizado com sucesso!"
    @cliente = cliente
    erb :editar_cliente
  else
    @erro = "Cliente não encontrado."
    redirect '/admin/clientes'
  end
end
